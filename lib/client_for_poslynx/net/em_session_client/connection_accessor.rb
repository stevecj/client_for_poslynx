# coding: utf-8

require_relative 'connection_accessor/connection_listener'

module ClientForPoslynx
  module Net
    class EM_SessionClient

      # Since we want to be able to reconnect and proceed after a connection
      # has been lost, and we cannot reuse an EventManager connection
      # handler after its connection has been closed.
      # This class allows us to make new connections using new connection
      # handlers as needed.
      class ConnectionAccessor
        def initialize(em_system, host, port, handler_class, opts={})
          @em_system      = em_system
          @host           = host
          @port           = port
          @handler_class  = handler_class
          @debug_logger   = opts.fetch( :debug_logger )
        end

        def get_connection(opts={})
          if connected?
            invoke_callable opts[:connected], current_connection_handler
          else
            open_connection opts
          end
        end

        def send_request(request_data, opts)
          if connected?
            _send_request request_data, opts
          else
            get_connection(
              connected: ->(*args){
                _send_request request_data, opts
              },
              failed_connection: opts[:failed]
            )
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

        def _send_request(request_data, opts)
          connection_listener.set_callbacks do |c|
            c.receive_response = opts[:responded]
            c.unbind = opts[:failed]
          end
          current_connection_handler.send_request request_data
        end

        def current_connection_handler
          connection_listener.latest_conn_handler
        end

        def connection_listener
          @connection_listener ||= ConnectionAccessor::ConnectionListener.new
        end

        def connected?
          connection_listener.is_connected
        end

        def open_connection(opts)
          debug_logger.call "session client initiating connection"
          em_system.connect(
            host, port, handler_class,
            connection_listener,
            debug_logger: debug_logger,
          )
          unless opts.empty?
            connection_listener.set_callbacks do |c|
              c.connection_completed = connection_reaction( opts[:connected] )
              c.unbind               = connection_reaction( opts[:failed_connection] )
            end
          end
        end

        def connection_reaction(response_listener)
          ->(conn_handler) {
            invoke_callable response_listener, conn_handler
          }
        end

        def invoke_callable(callable, *args)
          callable.call( *args ) unless callable.nil?
        end
      end

    end
  end
end
