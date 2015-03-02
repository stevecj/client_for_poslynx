# coding: utf-8

require_relative 'em_connector/handles_connection'
require_relative 'em_connector/connection_handler'
require_relative 'em_connector/event_dispatcher'

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
      # Creates a new
      # <tt>ClientForPoslynx::Net::EM_Connector</tt>
      # instance.
      #
      # The <tt>server</tt> and <tt>port</tt> arguments are
      # passed to Event Manager's methods for connecting or
      # reconnecting to the poslynx lane as needed.
      #
      # ==== Options
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
        @handler_class = opts.fetch( :handler,   EM_Connector::ConnectionHandler )
        @em_system     = opts.fetch( :em_system, ::EM )
        self.connection_state = :initial
      end

      # The POSLynx server to be conected to.
      attr_reader :server

      # The server port through which to connected.
      attr_reader :port

      # The connection handler instance (connection) after the
      # first call to <tt>#connect</tt>.  It will be an instance
      # of the connection handler class.
      attr_reader :connection

      # The current connection state. One of <tt>:initial</tt>,
      # <tt>:connecting</tt>, <tt>:connected</tt>,
      # <tt>:disconnecting</tt>, <tt>:disconnected</tt>.
      attr_reader :connection_state

      # The connection handler class to be passed as the
      # handler argument to <tt>EM::connect</tt>.
      attr_reader :handler_class

      # The Event Manager system that will be called on for
      # making connections.
      attr_reader :em_system

      # Asynchronously attempts to open an EventMachine
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
      # If another <tt>#connect</tt> request is already pending,
      # then the the new request is combined with the pending
      # request, and the appropriate callback will be invoked
      # for each of those when the connection attempt is
      # subsequently concluded.
      #
      # ==== Options
      # * <tt>:on_success</tt> - An object to receive
      #   <tt>#call</tt> when the connection is successfully
      #   opened.
      # * <tt>:on_failure</tt> - An object to receive
      #   <tt>#call</tt> when the connection attempt fails.
      def connect(opts={})
        case connection_state
        when :initial
          make_initial_connection opts
        when :connected
          opts[:on_success].call if opts[:on_success]
        when :connecting
          piggyback_connect opts
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
      # Note that you might never have reason to call this since
      # Event Machine automatically closes connections when the
      # run loop is stopped.
      #
      # ==== Options
      # * <tt>:on_completed</tt> - An object to receive
      #   <tt>#call</tt> when finished disconnecting.
      def disconnect(opts={})
        if connection_state == :connected
          connection.event_dispatcher =
            EM_Connector::EventDispatcher.for_disconnect(connection, opts)
          self.connection_state = :disconnecting
          connection.close_connection
        else
          opts[:on_completed].call
        end
      end

      private

      attr_writer :connection, :connection_state

      def make_initial_connection(opts)
        handler_opts = {
          connection_setter: build_connection_setter( opts ),
          state_setter: method( :connection_state= ),
        }
        self.connection_state = :connecting
        em_system.connect \
          server, port,
          handler_class, handler_opts
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
        self.connection_state = :connecting
        connection.event_dispatcher = EM_Connector::EventDispatcher.for_connect(
          connection, connect_event_dispatch_opts
        )
        connection.reconnect server, port
      end

      def piggyback_connect(connect_event_dispatch_opts)
        connect_event_dispatch_opts = connect_event_dispatch_opts.merge(
          original_dispatcher: connection.event_dispatcher
        )
        connection.event_dispatcher = EM_Connector::EventDispatcher.for_connect(
          connection, connect_event_dispatch_opts
        )
      end

    end

  end
end
