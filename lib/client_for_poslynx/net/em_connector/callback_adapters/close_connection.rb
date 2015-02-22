# coding: utf-8

module ClientForPoslynx
  module Net
    class EM_Connector
      module CallbackAdapters

        class CloseConnection < CallbackAdapters::Base
          def unbind(handler)
            callback.call
          end
        end

      end
    end
  end
end
