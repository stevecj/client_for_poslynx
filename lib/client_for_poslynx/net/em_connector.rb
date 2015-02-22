# coding: utf-8

require_relative 'em_connector/handles_connection'
require_relative 'em_connector/event_listener'
require_relative 'em_connector/callback_adapters'

module ClientForPoslynx
  module Net

    # An instance of EM_Connector provides a simple API for
    # making requests to the POSLynx using the POSLynx
    # EventManager protocol and receiving call-backs with
    # the results of those requests.
    #
    # Unlike a raw EventManager connection handler instance, a
    # single EM_Connection instance can be re-connected and
    # re-used after a connection has been closed.
    class EM_Connector
      NullConnectCallback     = ->(handler, success) { }
      NullSendRequestCallback = ->(response)         { }

      attr_reader :host, :port, :em_system, :connection_class

      def initialize(host, port, opts={})
        @host = host
        @port = port
        use_ssl = opts.fetch( :use_ssl, false )
        @em_system = opts.fetch( :em_system, EM )
        em_conn_base_class =
          opts.fetch( :em_connection_base_class, EM::Connection )
        @connection_class = Class.new( em_conn_base_class ) do
          include EM_Connector::HandlesConnection
          define_method :use_ssl do ; use_ssl ; end
        end
      end

      # Attempts to open a new connection if not currently
      # connected or utilize the current connection if currently
      # connected.
      #
      # causes the #call(handler, success) method to be called
      # for the given handler.  The connection handler argument
      # receives the connection handler used to make (or attempt
      # to make) the connection, and the success argument
      # receives `true` for a successful or existing connection,
      # `false` for an unsuccessful connection.
      #
      # Following an unsuccessful connection, #connect may be
      # re-tried, and it will start again with a new connection
      # handler in that case.
      #
      # Note that the #call method of the callback may be invoked
      # either synchronously or asynchronously.
      def connect(callback = NullConnectCallback)
        if currently_connected?
          callback.call current_handler, true
        else
          _event_listener.callback_adapter = CallbackAdapters::Connect.new( callback )
          em_system.connect(
            host, port,
            connection_class,
            _event_listener,
          )
        end
      end

      # Given a request data object (see
      # ClientForPoslynx::Data:Requests) sends the request to
      # the POSLynx using the currently open connection.
      #
      # The #call(response_data, connected_status) method of the
      # given callback object will be invoked.  response_data
      # will receive a response data object (see
      # ClientForPoslynx::Data:Responses) containing the response
      # received from the POSLynx or nil if no response could be
      # received.  connected_status will receive true if the
      # response was successfully received or false if there is
      # no currently linked connection or if the connection is
      # lost before a result is received.
      #
      # #TODO: Properly respond to the case in which the
      #        connection is lost while waiting for a response as
      #        described above.
      def send_request(request_data, callback = NullSendRequestCallback)
        if currently_connected?
          _event_listener.callback_adapter = CallbackAdapters::SendRequest.new( callback )
          current_handler.send_request request_data
        else
          callback.call nil, false
        end
      end

      # The current or most recent connection handler.
      def current_handler
        _event_listener.current_handler
      end

      # True if a connection has been successfully made and has
      # not been subsequently unbound.
      def currently_connected?
        current_handler && ! unbound?
      end

      # True if the most recent connection attempt failed or the
      # most recent successful connectino has been subsequently
      # unbound.
      def unbound?
        _event_listener.unbound?
      end

      def _event_listener
        @event_listener ||= EM_Connector::EventListener.new
      end
    end

  end
end
