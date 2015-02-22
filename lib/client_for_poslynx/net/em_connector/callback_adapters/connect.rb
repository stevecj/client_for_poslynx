# coding: utf-8

module ClientForPoslynx
  module Net
    class EM_Connector
      module CallbackAdapters

        class Connect < CallbackAdapters::Base
          def connection_completed(handler)
            callback.call handler, true
          end

          def unbind(handler)
            callback.call handler, false
          end
        end

      end
    end
  end
end
