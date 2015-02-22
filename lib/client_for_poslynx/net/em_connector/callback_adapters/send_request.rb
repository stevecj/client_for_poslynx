# coding: utf-8

module ClientForPoslynx
  module Net
    class EM_Connector
      module CallbackAdapters

        class SendRequest < CallbackAdapters::Base
          def unbind(handler)
            callback.call nil, false
          end

          def receive_response(response_data)
            callback.call response_data, true
          end
        end

      end
    end
  end
end
