# coding: utf-8

module ClientForPoslynx
  module FakePosTerminal
    class ConsoleUserInterface
      module RequestProcessors

        class PinPadDisplaySpecifiedFormProcessor < AbstractProcessor
          #TODO: Handle simpulated signature?
          #TODO: Handle long text?

          def call
            if has_buttons?
              ui.show_message_with_buttons text_values, request.button_labels
              ui.fetch_button_selection request.button_labels, method( :respond_with_selected_button )
            else
              ui.show_message text_values
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

          def text_values
            if request.text_values.length > 1
              request.text_values.each_with_index.map{ |text, idx|
                value_num = idx + 1
                't%d : %s' % [value_num, text]
              }
            else
              request.text_values
            end
          end

        end

      end
    end
  end
end
