# coding: utf-8

module ClientForPoslynx
  module FakePosTerminal
    class ConsoleUserInterface
      module RequestProcessors

        class PinPadInitializeProcessor < AbstractProcessor

          def call
            ui.reset request.idle_prompt
            set_result '0000', 'Success', 'Success'
            respond
          end

        end

      end
    end
  end
end
