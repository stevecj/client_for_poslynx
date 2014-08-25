# coding: utf-8

module ClientForPoslynx
  module FakePosTerminal
    module RequestHandlers

      class PinPadDisplayMessage < RequestHandlers::AbstractHandler

        def call
          @response = Data::Responses::PinPadDisplayMessage.new
          if Array(request.button_labels).empty?
            handle_without_buttons
          else
            handle_with_buttons
          end

          set_result '0000', 'SUCCESS', 'Success message...'
        end

        private

        def handle_without_buttons
          user_interface.show_message request.text_lines
          response.button_response = "no buttons"
        end

        def handle_with_buttons
          user_interface.show_message_with_buttons request.text_lines, request.button_labels
          response.button_response = user_interface.get_button_selection( request.button_labels )
        end
      end

    end
  end
end
