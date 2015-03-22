# coding: utf-8

module ClientForPoslynx
  module Net
    class EM_Connector

      class EventDispatcher
        NULL_LISTENER = ->(*) { }

        class << self
          private :new

          def null(connection)
            new( connection )
          end

          def for_connect(connection, opts)
            original_dispatcher = opts[:original_dispatcher]
            callback_map = EM_Connector.CallbackMap(
              connection_completed: opts[:on_success],
              unbind:               opts[:on_failure],
            )
            new( connection, original_dispatcher, callback_map )
          end

          def for_disconnect(connection, opts)
            callback_map = EM_Connector.CallbackMap(
              unbind: opts[:on_completed]
            )
            new( connection, nil, callback_map )
          end

          def for_send_request(connection, opts)
            callback_map = EM_Connector.CallbackMap(
              receive_response: opts[:on_response],
              unbind:           opts[:on_failure],
            )
            new( connection, nil, callback_map )
          end
        end

        def initialize(connection, original_dispatcher = nil, callback_map = EM_Connector.CallbackMap())
          @connection = connection
          @original_dispatcher = original_dispatcher
          @callback_map = callback_map
        end

        def []=(event_type, callback)
          callback_map[event_type] = callback
        end

        def event_occurred(event_type, *args)
          connection.reset_event_dispatcher
          original_dispatcher.event_occurred( event_type, *args ) if original_dispatcher
          callback_map.call event_type, *args
        end

        private

        attr_reader :connection, :original_dispatcher, :callback_map

      end

    end
  end
end
