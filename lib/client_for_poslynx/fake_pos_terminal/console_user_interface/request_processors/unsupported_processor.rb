# coding: utf-8

module ClientForPoslynx
  module FakePosTerminal
    class ConsoleUserInterface
      module RequestProcessors

        class UnsupportedProcessor < AbstractProcessor

          def call
            set_result '0106', "Service Not Supported", "Don't know how to process request"
            respond
          end

        end

      end
    end
  end
end
