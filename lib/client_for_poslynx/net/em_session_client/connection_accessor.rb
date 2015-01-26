# coding: utf-8

module ClientForPoslynx
  module Net
    class EM_SessionClient

      class ConnectionAccessor
        def initialize(em_system, host, port, handler_class, connection_listener, opts={})
          @em_system           = em_system
          @host                = host
          @port                = port
          @handler_class       = handler_class
          @connection_listener = connection_listener
          @debug_logger        = opts.fetch( :debug_logger )
        end

        def call(opts={})
          if connection_listener.is_connected
            invoke_callable opts[:connected]
          else
            open_connection opts
          end
        end

        private

        attr_reader(
          :em_system,
          :host,
          :port,
          :handler_class,
          :connection_listener,
          :debug_logger,
        )

        def open_connection(opts)
          debug_logger.call "session client initiating connection"
          em_system.connect(
            host, port, handler_class,
            connection_listener,
            debug_logger: debug_logger,
          )
          unless opts.empty?
            connection_listener.on_connection_completed = connection_reaction( opts[:connected] )
            connection_listener.on_unbind = connection_reaction( opts[:failed_connection] )
          end
        end

        def connection_reaction(response_listener)
          ->() {
            connect_done!
            invoke_callable response_listener
          }
        end

        def connect_done!
          connection_listener.on_connection_completed = nil
          connection_listener.on_unbind = nil
        end

        def invoke_callable(callable, *args)
          callable.call( *args ) unless callable.nil?
        end
      end

    end
  end
end
