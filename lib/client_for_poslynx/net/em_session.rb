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
      class ConflictingRequestError < Error ; end

      # Executes the given block in the context of a session
      # attached to the given Event Machine connector.  The
      # session is passed as the argument to the block.
      def self.execute(connector)
        new( connector ).execute { |s| yield s }
      end

      attr_reader :connector

      attr_reader :status

      # Builds a new EM_Session instance attached to the given
      # Event Machine connector.
      def initialize(connector)
        self.connector = connector
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
      # the response to this request is still received, then the
      # response is returned as normal, but this session's status
      # is changed to detached, and any subsequent request
      # attempts made in this session will result in
      # <tt>RequestError</tt> being raised.
      #
      # If another session is already waiting for a response,
      # then this will attempt to usurp or supplant the other
      # request.  If the new request is of the same type as the
      # existing request, and the type is not PinPadReset, then
      # this call will raise a <tt>ConflictingRequestError</tt>
      # exception.
      def request(data)
        raise RequestError if status == :detached
        if connector.request_pending?
          pending_request_data = connector.latest_request.request_data
          pending_callbacks = connector.latest_request.result_callbacks
          if Data::Requests::PinPadReset === data && Data::Requests::PinPadReset === pending_request_data
            pending_callbacks.call :on_failure
            was_successful, resp_data_or_ex = Fiber.yield( [:_get_response] )
          elsif data.class == pending_request_data.class
            raise ConflictingRequestError, "Attempted a request while another request of the same type is in progress"
          else
            was_successful, resp_data_or_ex = Fiber.yield( [:_request, data, connector.latest_request] )
          end
        else
          was_successful, resp_data_or_ex = Fiber.yield( [:_request, data] )
        end
        raise resp_data_or_ex unless was_successful
        resp_data_or_ex
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
      rescue StandardError => e
        dispatch fiber.resume( [false, e] )
      end

      def _get_response
        connector.get_response response_handlers
      end

      def response_handlers(overlaps_request=nil)
        overlapped_request_data = overlaps_request && overlaps_request.request_data
        overlapped_request_callbacks = overlaps_request && overlaps_request.result_callbacks
        {
          on_response: ->(response_data) {
            if overlapped_request_data && overlapped_request_data.class.response_class === response_data
              overlapped_request_callbacks.call :on_detached
              overlapped_request_callbacks.call :on_response, response_data
              _get_response
            else
              overlapped_request_callbacks.call :on_failure if overlapped_request_data
              dispatch fiber.resume( [true, response_data] )
            end
          },
          on_failure: ->() {
            overlapped_request_callbacks.call :on_failure if overlapped_request_data
            dispatch fiber.resume( [false, RequestError.new] )
          },
          on_detached: ->(){
            detach!
          },
        }
      end

      def detach!
        self.connector = nil
        self.status = :detached
      end
    end

  end
end
