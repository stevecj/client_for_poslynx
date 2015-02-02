# coding: utf-8

require_relative 'em_session_client/connection_accessor'
require_relative 'em_session_client/handles_connection'
require_relative 'em_session_client/session'

module ClientForPoslynx
  module Net

    class EM_SessionClient

      class EM_ConnectionBase < EM::Connection
        include EM::Protocols::POSLynx
      end

      module NullDebugLogger
        extend self
        def call(message) ; end
      end

      def initialize(host, port, opts={})
        @host = host
        @port = port
        @debug_logger = opts.fetch( :debug_logger ) { NullDebugLogger }
        @em_system = opts.fetch(:em_system){ ::EM }
        @connection_base_class = opts.fetch(:connection_base_class) { EM_ConnectionBase }
      end

      def start_session(opts = {})
        session_connect_proc = nil
        session = EM_SessionClient::Session.new(
          session_pool, connection_accessor
        ) { |scp| session_connect_proc = scp }
        session_pool << session
        session_connect_proc.call(
          connected:         session_init_listener_for( opts[:connected],         session ),
          failed_connection: session_init_listener_for( opts[:failed_connection], session ),
        )
      end

      private

      attr_reader(
        :host,
        :port,
        :em_system,
        :connection_base_class,
        :debug_logger,
      )

      def connection_handler_class
        @connection_handler_class ||= Class.new( connection_base_class ) do
          include EM_SessionClient::HandlesConnection
        end
      end

      def session_pool
        @session_pool ||= []
      end

      def connection_accessor
        @connection_accessor ||= ConnectionAccessor.new(
          em_system, host, port, connection_handler_class,
          debug_logger: debug_logger,
        )
      end

      def session_init_listener_for(listener, session)
        listener.nil? ?
          ->(*) { } :
          ->(*) { listener.call session }
      end
    end

  end
end
