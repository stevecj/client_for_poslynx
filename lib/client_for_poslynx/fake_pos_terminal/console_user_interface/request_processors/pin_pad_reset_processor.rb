# coding: utf-8

module ClientForPoslynx
  module FakePosTerminal
    class ConsoleUserInterface
      module RequestProcessors

        class PinPadResetProcessor < AbstractProcessor

          def call
            reset
            set_result '0000', 'Success', 'Success'
            respond
          end

        end

      end
    end
  end
end
