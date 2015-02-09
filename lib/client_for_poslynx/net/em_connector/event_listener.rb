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
        attr_accessor :current_handler
        private       :current_handler=

        def to_em_connector_callback_adapter
          self
        end

        def connection_completed(handler)
          self.current_handler = handler
          callback_adapter.connection_completed(handler)
        end

        def unbind(handler)
          callback_adapter.unbind(handler)
        end

        private

        def callback_adapter
          @callback_adapter ||= NullCallbackAdapter
        end

      end

    end
  end
end
