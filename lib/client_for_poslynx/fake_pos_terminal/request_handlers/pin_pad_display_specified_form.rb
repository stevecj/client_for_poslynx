# coding: utf-8

module ClientForPoslynx
  module FakePosTerminal
    module RequestHandlers

      class PinPadDisplaySpecifiedForm < RequestHandlers::AbstractHandler

        #TODO: Handle simpulated signature?
        #TODO: Handle long text?

        def call
          @response = Data::Responses::PinPadDisplaySpecifiedForm.new
          if Array(request.button_labels).empty?
            handle_without_buttons
          else
            handle_with_buttons
          end

          set_result '0000', 'SUCCESS', 'Success'
        end

        private

        def handle_without_buttons
          user_interface.show_message text_values
          response.button_response = "no buttons"
        end

        def handle_with_buttons
          user_interface.show_message_with_buttons text_values, request.button_labels
          response.button_response = user_interface.get_button_selection( request.button_labels )
        end

        def text_values
          if request.text_values.length > 1
            request.text_values.each_with_index.map{ |text, idx|
              value_num = idx + 1
              't%d : %s' % [value_num, text]
            }
          else
            text_values
          end
        end
      end

    end
  end
end
