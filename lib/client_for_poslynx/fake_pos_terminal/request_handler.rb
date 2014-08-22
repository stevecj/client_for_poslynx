# coding: utf-8

require 'client_for_poslynx'
require_relative 'request_handler/visa_receipt_formatter'

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

      def visit_CreditCardSale(request_data)
        response = Data::Responses::CreditCardSale.new
        response.client_id            = request_data.client_id
        response.merchant_supplied_id = request_data.merchant_supplied_id
        if request_data.input_source == 'EXTERNAL'
          user_interface.show_card_swipe_request total: request_data.amount, transaction: 'PURCHASE'
          response.card_number_last_4 = user_interface.get_fake_card_swipe
          user_interface.show_payment_confirmation request_data.amount
          confirmed = user_interface.get_confirmation

          fill_external_credit_card_sale_response response, request_data, confirmed
        else
          response.result = 'Transaction Not Supported'
          response.error_code = '0135'
          response.result_test = "Fake POSLynx doesn't currently support input source other than EXTERNAL"
          update_status_line response.result_test
        end
        response
      end

      private

      def fill_external_credit_card_sale_response(response, request_data, confirmed)
        now = Time.now

        response.result      = confirmed ? 'APPROVED' : 'ERROR'
        response.error_code  = confirmed ? '0000'     : '0092'
        response.result_text = confirmed ? "Approval" : 'CANCELLED'

        if confirmed
          response.processor_authorization = '1234567'
          response.record_number           = '121212'
          response.reference_data          = '123456789012'
          response.authorized_amount       = request_data.amount
        end

        response.merchant_supplied_id = request_data.merchant_supplied_id
        response.client_id            = response.client_id

        response.card_type        = 'Visa'
        response.merchant_id      = '9876543221098'
        response.terminal_id      = '12345678'
        response.transaction_date = now.strftime('%m%d%y')
        response.transaction_time = now.strftime('%H%M%S')

        receipt_formatter = RequestHandler::VisaReceiptFormatter.new( request_data, response )
        response.receipt          = receipt_formatter.call( :merchant)
        response.customer_receipt = receipt_formatter.call( :customer)
      end

    end

  end
end
