# coding: utf-8

module ClientForPoslynx
  module Net
    class EM_Connector ; end

    # Convenient shorthand for EM_Connector for use within
    # Net and its sub-nested classes and modules.
    EMC = EM_Connector
  end
end

require_relative 'em_connector/connector_state'
require_relative 'em_connector/handles_connection'
require_relative 'em_connector/connection_handler'
require_relative 'em_connector/event_dispatcher'
require_relative 'em_connector/request_call'
require_relative 'em_connector/callback_map'

module ClientForPoslynx
  module Net

    # A <tt>ClientForPoslynx::Net::EM_Connector</tt> object is
    # associated with a specific POSLynx host (lane) and provides
    # a convenient means of connecting or re-connecting to the
    # host any number of times within an Event Manager run loop.
    #
    # An instance of <tt>ClientForPoslynx::Net::EM_Connector</tt>
    # may be created either inside or outside of a run loop, but
    # it must be used from within a run loop to make or interact
    # with connections since that's the only context in which
    # Event Manager connections are applicable.
    class EM_Connector
      extend Forwardable

      # Creates a new
      # <tt>ClientForPoslynx::Net::EM_Connector</tt>
      # instance.
      #
      # The <tt>server</tt> and <tt>port</tt> arguments are
      # passed to Event Manager's methods for connecting or
      # reconnecting to the poslynx lane as needed.
      #
      # ==== Options
      # * <tt>:encryption<tt> - <tt>:use_ssl</tt> if SSL
      #   if the connection should be encrypted using SSL.
      #   <tt>:none</tt> if the connection should not be
      #   encrypted. Defaults to <tt>:none</tt>.
      # * <tt>:handler<tt> - The class given as the handler
      #   argument to the <tt>::connect</tt> call to the Event
      #   Machine system (normally <tt>::EM</tt>).
      #   Defaults to
      #   <tt>ClientForPoslynx::Net::EM_Connector::ConnectionHandler</tt>
      #   This should generally be a subclass of
      #   <tt>ClientForPoslynx::Net::EM_Connector::ConnectionHandler</tt>
      #   or be a class that includes
      #   <tt>ClientforPoslynx::Net::EM_Connector::HandlesConnection</tt>
      #   and is a subclass of <tt>EM::Connection</tt>.
      #   When using a substitute for <tt>::EM</tt> as the Event
      #   Machine system, this might not need to be a subclass of
      #   <tt>EM::Connection</tt>, though it will need to supply
      #   substitute implementations of several of the
      #   <tt>EM::Connection</tt> methods in that case.
      # * <tt>:em_system</tt> - The event machine system that
      #   will be called on for making connections.  Defaults
      #   to <tt>::EM</tt>.  Must implement the <tt>::connect</tt>
      #   method.
      #   This is used for dependency injection in unit tests and
      #   may be useful for inserting instrumentation arround the
      #   <tt>::connect</tt> call within an application.
      def initialize(server, port, opts={})
        @server = server
        @port   = port
        state.encryption = opts.fetch( :encryption, :none )
        @handler_class = opts.fetch( :handler,   EMC::ConnectionHandler )
        @em_system     = opts.fetch( :em_system, ::EM )
        state.connection_status ||= :initial
        state.status_of_request ||= :initial
      end

      # The POSLynx server to be conected to.
      attr_reader :server

      # The server port through which to connected.
      attr_reader :port

      # The encryption mode <tt>:use_ssl</tt> or <tt>:none</tt>
      def_delegator :state, :encryption

      # The connection handler instance (connection) after the
      # first call to <tt>#connect</tt>.  It will be an instance
      # of the connection handler class.
      def connection
        state.connection
      end

      # The current connection status. One of <tt>:initial</tt>,
      # <tt>:connecting</tt>, <tt>:connected</tt>,
      # <tt>:disconnecting</tt>, <tt>:disconnected</tt>.
      def_delegator :state, :connection_status

      # True when no connection attempt has been initiated yet.
      def_delegator :state, :connection_initial?

      # True when a connection attempt is in progress.
      def_delegator :state, :connecting?

      # True when currently connected.
      def_delegator :state, :connected?

      # True when disconnection is in progress.
      def_delegator :state, :disconnecting?

      # True when a opening a connection has been previously
      # attempted or successful, and not currently connected.
      def_delegator :state, :disconnected?

      # An instance of <tt>EM_Connector::RequestCall</tt>
      # containing the request data and result callbacks from the
      # most recent <tt>#send_request</tt> or
      # <tt>#get_response</tt> call.
      attr_reader :latest_request

      # The current <tt>#send_request</tt> status. One of
      # <tt>:initial</tt>, <tt>:pending</tt>,
      # <tt>:got_response</tt>, <tt>:failed</tt>.
      def_delegator :state, :status_of_request

      # True when no request-send has been initiated yet.
      def_delegator :state, :request_initial?

      # True when a request-send is in progress.
      def_delegator :state, :request_pending?

      # True when a response was receied from the most recently
      # attempted request-send.
      def_delegator :state, :got_response?

      # True when the most recently attempted request-send
      # resulted in failure.
      def_delegator :state, :request_failed?

      # The connection handler class to be passed as the handler
      # argument to <tt>EM::connect</tt>.
      attr_reader :handler_class

      # The Event Manager system that will be called on for
      # making connections.
      attr_reader :em_system

      # Asynchronously attempts to open an EventMachine
      # connection to the POSLynx lane.
      #
      # The underlying connection instance is available via
      # <tt>#connection</tt> immediately after the call returns,
      # though it might not yet represent a completed, open
      # connection.
      #
      # If the connector already has a currently open connection,
      # then the call to <tt>#connect</tt> succeeds immediately
      # and synchronously.
      #
      # Once the connection is completed or fails, the
      # <tt>#call</tt> method of the apporopriate callback
      # object (if supplied) is invoked with no arguments.
      #
      # If another <tt>#connect</tt> request is already pending,
      # then the the new request is combined with the pending for
      # request, and the appropriate callback will be invoked
      # each of those when the connection attempt is subsequently
      # concluded.
      #
      # ==== Result callback options
      # * <tt>:on_success</tt> - An object to receive
      #   <tt>#call</tt> when the connection is successfully
      #   opened.
      # * <tt>:on_failure</tt> - An object to receive
      #   <tt>#call</tt> when the connection attempt fails.
      def connect(result_callbacks={})
        result_callbacks = EMC.CallbackMap(result_callbacks)
        if connection_initial?
          make_initial_connection result_callbacks
        elsif connected?
          result_callbacks.call :on_success
        elsif connecting?
          piggyback_connect result_callbacks
        else
          reconnect result_callbacks
        end
      end

      # When called from within an EventManager event-handling
      # loop, asynchronously attempts to disconnect the current
      # EventMachine connection to the POSLynx lane.
      #
      # If there is no currently open connection, then the call
      # to <tt>#disconnect</tt> succeeds immediately and
      # synchronously.
      #
      # Note that you might never have reason to call this since
      # Event Machine automatically closes connections when the
      # run loop is stopped.
      #
      # ==== Result callback options
      # * <tt>:on_completed</tt> - An object to receive
      #   <tt>#call</tt> when finished disconnecting.
      def disconnect(result_callbacks={})
        result_callbacks = EMC.CallbackMap( result_callbacks )
        if connected?
          connection.event_dispatcher =
            EMC::EventDispatcher.for_disconnect( connection, result_callbacks )
          state.connection_status = :disconnecting
          connection.close_connection
        else
          result_callbacks.call :on_completed
        end
      end

      # When called with an open connection, asynchronously sends
      # a request to the POSLynx with the given request data.
      #
      # When the response is received, the response data is
      # passed to the <tt>#call</tt> method of the
      # <tt>:on_response</tt> handler.
      #
      # If <tt>#send_request</tt> is called without an open
      # connection or when the connection is lost before any
      # response is received, the <tt>#call</tt> method of the
      # <tt>:on_failure</tt> callback is invoked.
      #
      # * <tt>request_data</tt> - The request to be sent. Should
      #   be an instance of one of the
      #   <tt>ClientForPoslynx::Data::Requests::...</tt> classes.
      # * <tt>result_callbacks</tt> - A hash map of objects, each
      #   of which handles a response condition when it receives
      #   <tt>#call</tt>
      #
      # ==== Result callback options
      # * <tt>:on_response</tt> - An object to receive
      #   <tt>#call</tt> with the response data when the response
      #   is received.
      # * <tt>:on_failure</tt> - An object to receive
      #   <tt>#call</tt> if there is no open connection or when
      #   the connection is lost.
      # * Any other callback(s) that might need to be received
      #   from a collaborator via <tt>#latest_request</tt> data
      #   while the request is pending. <tt>EMSession</tt> may
      #   invoke an <tt>:on_detached</tt> callback, for example.
      def send_request(request_data, result_callbacks={})
        result_callbacks = EMC.CallbackMap( result_callbacks )
        unless connected?
          result_callbacks.call :on_failure
          return
        end
        self.latest_request = EMC.RequestCall( request_data, result_callbacks )
        state.status_of_request = :pending
        connection.event_dispatcher = EMC::EventDispatcher.for_send_request(
          connection, result_callbacks
        )
        connection.send_request request_data
      end

      # This methid exists to support 2 special-case scenarios
      # that client code may need to handle.
      #
      # Scenario A:
      #
      # A request is in progress, and the original result
      # handlers must be replaced with new handlers.  For
      # instance, a PIN Pad Reset may have been in progress to
      # initate one workflow, and that workflow is being aborted
      # to initiate a different workflow.
      #
      # Scenario B:
      #
      # An attempt was made to cancel a previous pending request
      # by sending another request, but a response to the
      # original request was subsequently received because it was
      # already in transit.  Now, we need to resume waiting for
      # the response to the second request since it is actually
      # still pending.
      #
      # The options for <tt>#get_response</tt> are the same as
      # for <tt>#send_request</tt> and have the same meanings,
      # but since no new request is to be made, there is no
      # <tt>request_data</tt> argument.
      #
      # If the <tt>#status_of_request</tt> is
      # <tt>:got_response</tt> before the invocation, then it is
      # reverted to # <tt>:pending</tt>.
      def get_response(result_callbacks={})
        result_callbacks = EMC.CallbackMap( result_callbacks )
        unless connected? && ( request_pending? || got_response? )
          result_callbacks.call :on_failure
          return
        end
        self.latest_request = EMC.RequestCall( latest_request.request_data, result_callbacks )
        state.status_of_request = :pending
        connection.event_dispatcher = EMC::EventDispatcher.for_send_request(
          connection, result_callbacks
        )
      end

      private

      def state
        @state ||= State.new
      end

      def latest_request=(value)
        args = Array(value)
        @latest_request = EMC.RequestCall( *args )
      end

      def make_initial_connection(result_callbacks)
        state.connection_status = :connecting
        em_system.connect \
          server, port,
          handler_class, state
        connection.event_dispatcher = EMC::EventDispatcher.for_connect(
          connection, result_callbacks
        )
      end

      def reconnect(connect_event_dispatch_opts)
        state.connection_status = :connecting
        connection.event_dispatcher = EMC::EventDispatcher.for_connect(
          connection, connect_event_dispatch_opts
        )
        connection.reconnect server, port
      end

      def piggyback_connect(response_callbacks)
        response_callbacks = response_callbacks.merge(
          original_dispatcher: connection.event_dispatcher
        )
        connection.event_dispatcher = EMC::EventDispatcher.for_connect(
          connection, response_callbacks
        )
      end
    end

  end
end
