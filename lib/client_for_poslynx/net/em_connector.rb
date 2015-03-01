# coding: utf-8

require_relative 'em_connector/handles_connection'
require_relative 'em_connector/connection_handler'

module ClientForPoslynx
  module Net

    class EM_Connector
      NULL_LISTENER = ->() { }

      attr_reader :host, :port, :em_system, :handler, :connection

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
        handler_opts = {
          host: host, port: port,
          connection_setter: ->(connection){ @connection = connection },
          on_connect_success: opts.fetch(:on_success, NULL_LISTENER),
          on_connect_failure: opts.fetch(:on_failure, NULL_LISTENER),
        }
        em_system.connect host, port, handler, handler_opts
      end

    end

  end
end
