# coding: utf-8

module ClientForPoslynx
  module Net
    class EM_Connector

      class EventListener
        module NullCallbackAdapter
          extend self
          def connection_completed(handler) ; end
          def unbind(handler)               ; end
        end

        attr_writer :callback_adapter
        attr_reader :current_handler

        def to_em_connector_callback_adapter
          self
        end

        def unbound?
          @unbound ||= false
        end

        def connection_completed(handler)
          @current_handler = handler
          callback_adapter.connection_completed handler
        end

        def unbind(handler)
          @current_handler = handler
          @unbound = true
          callback_adapter.unbind handler
        end

        def receive_response(response_data)
          callback_adapter.receive_response response_data
        end

        private

        def callback_adapter
          @callback_adapter ||= NullCallbackAdapter
        end

      end

    end
  end
end
