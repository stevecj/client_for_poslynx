# coding: utf-8

require_relative 'em_connector/handles_connection'
require_relative 'em_connector/connection_handler'
require_relative 'em_connector/event_dispatcher'

module ClientForPoslynx
  module Net

    class EM_Connector
      attr_reader(
        :host, :port,
        :em_system, :handler,
        :connection, :connection_state
      )

      # Creates a new ClientForPoslynx::Net::EM_Connector
      # instance.
      def initialize(host, port, opts={})
        @host = host
        @port = port
        @em_system = opts.fetch( :em_system, ::EM )
        @handler   = opts.fetch( :handler, EM_Connector::ConnectionHandler )
      end

      # When called from within an EventManager event-handling
      # loop, asynchronously attempts to open an EventMachine
      # connection to the POSLynx lane.
      #
      # The underlying connection instance is available
      # via <tt>#connection</tt> immediately after the call
      # returns, though it might not yet represent a completed,
      # open connection.
      #
      # If the connector already has a currently open connection,
      # then the call to <tt>#connect</tt> succeeds immediately
      # and synchronously.
      #
      # Once the connection is completed or fails, the
      # <tt>#call</tt> method of the apporopriate callback
      # object (if supplied) is invoked with no arguments.
      #
      # ==== Options
      # * <tt>:on_success<tt> - An object to receive
      #   <tt>#call</tt> when the connection is successfully
      #   opened.
      # * <tt>:on_failure</tt> - An object to receive
      #   <tt>#call</tt> when the connection attempt fails.
      def connect(opts={})
        if never_attempted_connection?
          make_initial_connection opts
        elsif connection_state == :connected
          on_success = opts[:on_success]
          on_success.call if on_success
        else
          reconnect opts
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
      # ==== Options
      # * <tt>:on_completed<tt> - An object to receive
      #   <tt>#call</tt> when finished disconnecting.
      def disconnect(opts={})
        if connection_state == :connected
          connection.event_dispatcher =
            EM_Connector::EventDispatcher.for_disconnect(connection, opts)
          connection.close_connection
        else
          opts[:on_completed].call
        end
      end

      private

      attr_writer :connection, :connection_state

      def never_attempted_connection?
        ! connection
      end

      def make_initial_connection(opts)
        handler_opts = {
          connection_setter: build_connection_setter( opts ),
          state_setter: method( :connection_state= ),
        }
        em_system.connect \
          host, port,
          handler, handler_opts
      end

      def build_connection_setter(connect_event_dispatch_opts)
       ->(connection) {
          @connection = connection
          connection.event_dispatcher = EM_Connector::EventDispatcher.for_connect(
            @connection, connect_event_dispatch_opts
          )
        }
      end

      def reconnect(connect_event_dispatch_opts)
        connection.event_dispatcher = EM_Connector::EventDispatcher.for_connect(
          connection, connect_event_dispatch_opts
        )
        connection.reconnect host, port
      end

    end

  end
end
