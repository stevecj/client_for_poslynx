# coding: utf-8

module ClientForPoslynx
  module Net

    # Provides a synchronous, structured API for making
    # requests to POSLynx host using Event Machine and returning
    # responses when received.
    #
    # Eliminates the need for complicated and messy event
    # callback chains in POSLynx client code.
    #
    # Multiple sessions may be in effect at the same time,
    # interacting with the same POSLyx host by using the same
    # Event Machine connector.  This is important for performing
    # actions such as initiating a new payment interaction when
    # a previous interaction was abandoned.
    class EM_Session

      # Base class for errors raised by the session to code that
      # is running in the context of a sesssion.
      class Error < StandardError ; end

      # Raised when an error condition is detected while making
      # a request or while waiting for the response.
      class RequestError < Error ; end

      # Raised when attempting to make a request while another
      # session is waiting for a response to a request of the
      # same type (other than PinPadReset).
      class ConflictingRequestError < RequestError ; end

      # Raised when a request is attempted from within a session
      # that has been detached.
      class RequestAfterDetachedError < RequestError ; end

      # Executes the given block in the context of a session
      # attached to the given Event Machine connector.  The
      # session is passed as the argument to the block.
      def self.execute(connector)
        new( connector ).execute { |s| yield s }
      end

      attr_reader :connector

      attr_reader :status

      attr_reader :em_system

      # Builds a new EM_Session instance attached to the given
      # Event Machine connector.
      #
      # ==== Options
      # * <tt>:em_system</tt> - The event machine system that
      #   will be called on for operations such as adding timers
      #   and deferring actions.
      def initialize(connector, opts={})
        self.connector = connector
        @em_system = opts.fetch( :em_system, ::EM )
        self.status = :initialized
      end

      # Executes the given block in the context of the session
      # The session is passed as the argument to the block.
      def execute
        @fiber = Fiber.new do
          yield self
          :done
        end
        self.status = :engaged
        dispatch fiber.resume
      end

      # Called from within an executed block of code for the
      # session to send request data to the POSLynx and return
      # the response to the request once it is received.
      # If a connection could not be established or is lost
      # before a response can be received, then a
      # <tt>RequestError</tt> exception will be raised.
      #
      # If another session attempts to supplant this request, but
      # the response to this request is subsequently received,
      # then the response is returned as normal, but the
      # current session's status is also changed to detached, so
      # any subsequent request attempts made in the session will
      # result in <tt>RequestAfterDetachedError</tt> being
      # raised.
      #
      # If another session is already waiting for a response,
      # then this will attempt to usurp or supplant the other
      # request.  If the new request is of the same type as the
      # existing request, and the type is not PinPadReset, then
      # this call will raise a <tt>ConflictingRequestError</tt>
      # exception.
      def request(data)
        if status == :detached
          msg = "Session cannot make requests because it is detached"
          raise RequestAfterDetachedError, msg
        end
        if connector.request_pending?
          pending_request_data = connector.latest_request.request_data
          pending_callbacks = connector.latest_request.result_callbacks
          if Data::Requests::PinPadReset === data && Data::Requests::PinPadReset === pending_request_data
            pending_callbacks.call :on_failure
            was_successful, resp_data_or_ex = Fiber.yield( [:_get_response] )
          elsif data.class == pending_request_data.class
            msg = "Attempted a request while another request of the same type is in progress"
            raise ConflictingRequestError, msg
          else
            was_successful, resp_data_or_ex = Fiber.yield( [:_request, data, connector.latest_request] )
          end
        else
          was_successful, resp_data_or_ex = Fiber.yield( [:_request, data] )
        end
        raise resp_data_or_ex unless was_successful
        resp_data_or_ex
      end

      # Given a block argument, returns control to EventMachine,
      # executes the block in a separate thread, waits for the
      # thread to complete, and then returns the value returned
      # by the block.
      #
      # This is implemented behind the scenes using
      # EventMachine::defer and has the same considerations and
      # caveats.
      #
      # When a call to #exec_dissociated is nested within a
      # block passed to anothet call, only the outermost invo-
      # cation is deferred, and the inner call executes in the
      # same thread as the outer call.
      #
      # Note that methods of the session should not be called by
      # code within the block since those methods should only be
      # called from code running in the main event loop thread.
      def exec_dissociated(&block)
        @currently_dissociated ||= false

        if @currently_dissociated
          block.call
        else
          begin
            @currently_dissociated = true
            was_successful, resp_data_or_ex = Fiber.yield( [:_exec_dissociated, block] )
            raise resp_data_or_ex unless was_successful
            resp_data_or_ex
          ensure
            @currently_dissociated = false
          end
        end
      end

      # Returns control to EventMachine, and returns control to
      # the session code after the given delay-time in seconds.
      def sleep(delay_time)
        Fiber.yield [:_sleep, delay_time]
      end

      private

      attr_writer :connector, :status
      attr_reader :fiber

      def dispatch(fiber_callback)
        return if fiber_callback == :done
        send *fiber_callback
      end

      def _request(data, overlaps_request=nil)
        connector.connect(
          on_success: ->() {
            send_request_callbacks = response_handlers( overlaps_request )
            connector.send_request data, send_request_callbacks
          },
          on_failure: ->() {
            dispatch fiber.resume( [false, RequestError.new] )
          }
        )
      rescue => ex
        dispatch fiber.resume( [false, ex] )
      end

      def _get_response
        connector.get_response response_handlers
      end

      def response_handlers(overlaps_request=nil)
        overlapped_request_data = overlaps_request && overlaps_request.request_data
        overlapped_request_callbacks = overlaps_request && overlaps_request.result_callbacks
        {
          on_response: on_response_handler( overlaps_request ),
          on_failure: on_failure_handler( overlaps_request ),
          on_detached: ->(){ detach! },
        }
      end

      def on_response_handler(overlaps_request)
        overlaps_request ?
          on_response_handler_with_overlap( overlaps_request ) :
          simple_on_response_handler
      end

      def on_response_handler_with_overlap(overlaps_request)
        overlapped_request_data = overlaps_request && overlaps_request.request_data
        overlapped_request_callbacks = overlaps_request && overlaps_request.result_callbacks
        ->(response_data) {
          if overlapped_request_data.potential_response?( response_data )
            overlapped_request_callbacks.call :on_detached
            overlapped_request_callbacks.call :on_response, response_data
            _get_response
          else
            overlapped_request_callbacks.call :on_failure
            dispatch fiber.resume( [true, response_data] )
          end
        }
      end

      def simple_on_response_handler
        ->(response_data) {
          dispatch fiber.resume( [true, response_data] )
        }
      end

      def on_failure_handler(overlaps_request)
        overlaps_request ?
          on_failure_handler_with_overlap( overlaps_request ) :
          simple_on_failure_handler
      end

      def on_failure_handler_with_overlap(overlaps_request)
        overlapped_request_callbacks = overlaps_request && overlaps_request.result_callbacks
        ->() {
          overlapped_request_callbacks.call :on_failure if overlaps_request
          dispatch fiber.resume( [false, RequestError.new] )
        }
      end

      def simple_on_failure_handler
        ->() {
          dispatch fiber.resume( [false, RequestError.new] )
        }
      end

      def detach!
        self.connector = nil
        self.status = :detached
      end

      def _exec_dissociated op
        wrapped_op = ->() {
          begin
            result = op.call
            [true, result]
          rescue => ex
            [false, ex]
          end
        }
        callback = ->(result) do
          dispatch fiber.resume result
        end
        em_system.defer wrapped_op, callback
      end

      def _sleep(delay_time)
        callback = ->() {
          dispatch fiber.resume
        }
        em_system.add_timer delay_time, callback
      end
    end

  end
end
