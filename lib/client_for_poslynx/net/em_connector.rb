# coding: utf-8

require_relative 'em_connector/handles_connection'
require_relative 'em_connector/event_listener'

module ClientForPoslynx
  module Net

    # An instance of EM_Connector provides a simple API for
    # making requests to the POSLynx using the POSLynx
    # EventManager protocol and receiving call-backs with
    # the results of those requests.
    # Unlike a raw EventManager connection handler instance, a
    # single EM_Connection instance can be re-connected and
    # re-used after a connection has been closed.
    class EM_Connector
      attr_reader :host, :port, :em_system, :connection_class

      def initialize(host, port, opts={})
        @host = host
        @port = port
        @em_system = opts.fetch( :em_system ) { EM }
        em_conn_base_class = opts.fetch( :em_connection_base_class ) { EM::Connection }
        @connection_class = Class.new( em_conn_base_class ) do
          include EM_Connector::HandlesConnection
        end
      end

      def connect(callback = ->(handler) { } )
        event_listener.callback_adapter = ConnectCallbackAdapter.new( callback )
        em_system.connect(
          host, port,
          connection_class,
          event_listener
        )
      end

      class ConnectCallbackAdapter
        attr_reader :callback

        def initialize(callback)
          @callback = callback
        end

        def connection_completed(handler)
          callback.call handler, true
        end

        def unbind(handler)
          callback.call handler, false
        end
      end

      private

      def event_listener
        @event_listener ||= EM_Connector::EventListener.new
      end
    end

  end
end
