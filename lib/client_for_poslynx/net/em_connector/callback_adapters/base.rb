# coding: utf-8

module ClientForPoslynx
  module Net
    class EM_Connector
      module CallbackAdapters

        class Base
          attr_reader :callback

          def initialize(callback)
            @callback = callback
          end

          def connection_completed(handler)
            # Ignore by default.
          end

          def unbind(handler)
            # Ignore by default.
          end

          def receive_response(response_data)
            # Ignore by default.
          end
        end

      end
    end
  end
end
