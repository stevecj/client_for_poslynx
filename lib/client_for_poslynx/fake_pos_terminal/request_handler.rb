# coding: utf-8

require 'client_for_poslynx'

module ClientForPoslynx
  module FakePosTerminal

    class RequestHandler
      include Data::Requests::CanVisit

      attr_reader :user_interface

      def initialize(user_interface)
        @user_interface = user_interface
      end

      def visit_PinPadInitialize(request_data)
        user_interface.reset request_data.idle_prompt
        Data::Responses::PinPadInitialize.new.tap do |resp|
          resp.result      = 'SUCCESS'
          resp.result_text = "PinPad Initialized"
          resp.error_code  = '0000'
        end
      end

      def visit_PinPadDisplayMessage(request_data)
        response = Data::Responses::PinPadDisplayMessage.new
        if Array(request_data.button_labels).empty?
          user_interface.show_message request_data.text_lines
          response.button_response = "no buttons"
        else
          user_interface.show_message_with_buttons request_data.text_lines, request_data.button_labels
          response.button_response = user_interface.get_button_selection( request_data.button_labels )
        end

        response.result      = 'SUCCESS'
        response.result_text = "Success message..."
        response.error_code  = '0000'

        response
      end

    end

  end
end
