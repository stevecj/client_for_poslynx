# coding: utf-8

module ClientForPoslynx
  module FakePosTerminal
    class ConsoleUserInterface
      module RequestProcessors

        class PinPadDisplayMessageProcessor < AbstractProcessor

          def call
            if has_buttons?
              show_message_with_buttons request.text_lines, request.button_labels
              fetch_button_selection request.button_labels, method( :respond_with_selected_button )
            else
              show_message request.text_lines
              respond_with_no_buttons
            end
          end

          private

          def has_buttons?
            ! Array( request.button_labels ).empty?
          end

          def respond_with_selected_button( button_label )
            set_result '0000', 'Success', 'Success'
            response.button_response = button_label
            respond
          end

          def respond_with_no_buttons
            set_result '0000', 'Success', 'Success'
            response.button_response = "No Buttons"
            respond
          end

        end

      end
    end
  end
end
