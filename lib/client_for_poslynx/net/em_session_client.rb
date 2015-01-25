# coding: utf-8

require_relative 'em_session_client/handles_connection'
require_relative 'em_session_client/connection_listener'
require_relative 'em_session_client/session'

module ClientForPoslynx
  module Net

    class EM_SessionClient

      class EM_ConnectionBase < EM::Connection
        include EM::Protocols::POSLynx
      end

      module NullDebugLogger
        extend self

        def call(message)
        end
      end

      def initialize(host, port, opts={})
        @host = host
        @port = port
        @debug_logger = opts.fetch( :debug_logger ) { NullDebugLogger }
        @em_system = opts.fetch(:em_system){ ::EM }
        connection_base_class = opts.fetch(:connection_base_class) { EM_ConnectionBase }
        @connection_handler_class = Class.new( connection_base_class ) do
          include EM_SessionClient::HandlesConnection
        end
        @session_pool = []
        @connection_listener = EM_SessionClient::ConnectionListener.new( session_pool )
      end

      def start_session(opts = {})
        session = EM_SessionClient::Session.new( connection_listener, method(:connect) )
        session_pool << session
        if connection_listener.is_connected
          opts[:connected].call( session ) if opts[:connected]
        else
          connection_listener.on_connection_completed = ->(session) {
            connect_done!
            opts[:connected].call( session ) if opts[:connected]
          }
          connection_listener.on_unbind = ->(session) {
            connect_done!
            opts[:failed_connection].call( session ) if opts[:failed_connection]
          }
          connect
        end
      end

      private

      def connect_done!
        connection_listener.on_connection_completed = nil
        connection_listener.on_unbind = nil
      end

      attr_reader(
        :host,
        :port,
        :em_system,
        :connection_handler_class,
        :session_pool,
        :connection_listener,
        :debug_logger,
      )

      def connect
        debug_logger.call "session client initiating connection"
        em_system.connect(
          host, port, connection_handler_class,
          connection_listener,
          debug_logger: debug_logger,
        )
      end

    end

  end
end
