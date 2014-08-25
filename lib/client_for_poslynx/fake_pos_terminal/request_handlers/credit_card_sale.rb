# coding: utf-8

module ClientForPoslynx
  module FakePosTerminal
    module RequestHandlers

      class CreditCardSale < RequestHandlers::AbstractHandler

        def call
          @response = Data::Responses::CreditCardSale.new
          if request.input_source == 'EXTERNAL'
            handle_supported_source_request
          else
            handle_unsupported_source_request
          end
        end

        private

        def handle_supported_source_request
          response.card_number_last_4 = get_card_swipe
          confirmed = get_confirmation
          assemble_supported_source_response confirmed
        end

        def handle_unsupported_source_request
          set_result '0135', 'Transaction Not Supported'
          response.result_text = "Fake POSLynx doesn't currently support input source other than EXTERNAL"
          user_interface.update_status_line response.result_text
        end

        def get_card_swipe
          user_interface.show_card_swipe_request(
            total: request.amount,
            transaction: 'PURCHASE',
          )
          user_interface.get_fake_card_swipe
        end

        def get_confirmation
          user_interface.show_payment_confirmation request.amount
          user_interface.get_confirmation
        end

        def assemble_supported_source_response(confirmed)
          response.card_type = 'Visa'

          if confirmed
            assemble_confirmed_response_specifics
          else
            assemble_cancelled_response_specifics
          end

          assemble_request_response_passthrough
          assemble_fake_client_specifics
          assemble_response_transaction_datetime
          assemble_response_receipts
        end

        def assemble_confirmed_response_specifics
          set_result '0000', 'APPROVED', 'Approval'
          response.processor_authorization = '1234567'
          response.record_number           = '121212'
          response.reference_data          = '123456789012'
          response.authorized_amount       = request.amount
        end

        def assemble_cancelled_response_specifics
          set_result '0092', 'ERROR', 'CANCELLED'
        end

        def assemble_request_response_passthrough
          response.merchant_supplied_id = request.merchant_supplied_id
          response.client_id            = request.client_id
        end

        def assemble_fake_client_specifics
          response.merchant_id = '9876543221098'
          response.terminal_id = '12345678'
        end

        def assemble_response_transaction_datetime
          now = Time.now
          response.transaction_date = now.strftime('%m%d%y')
          response.transaction_time = now.strftime('%H%M%S')
        end

        def assemble_response_receipts
          receipt_assembler = FakePosTerminal::ResultAssemblers::CreditCardSaleReceipt.new( request, response )
          response.receipt          = receipt_assembler.call( :merchant)
          response.customer_receipt = receipt_assembler.call( :customer)
        end

      end

    end
  end
end
