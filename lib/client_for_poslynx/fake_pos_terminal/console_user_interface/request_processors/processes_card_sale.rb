# coding: utf-8

module ClientForPoslynx
  module FakePosTerminal
    class ConsoleUserInterface
      module RequestProcessors

        module ProcessesCardSale
          include Format

          def fetch_card_swipe(after)
            show_card_swipe_request
            ui.fetch_fake_card_swipe ->(last_4_digits){
              response.card_number_last_4 = last_4_digits
              response.input_method = 'SWIPED'
              response.card_type    = use_card_type
              after.call
            }
          end

          def show_card_swipe_request
            ui.display_content format_card_swipe_request
          end

          def format_card_swipe_request(options = {})
            total       = request.amount
            transaction = 'PURCHASE'
            lines = []
            lines << "Please swipe your card"
            lines << "Total: " + format_usd( total ) if total
            lines << "Transaction: " + transaction
            ui.format_multiline_message( lines )
          end

          def fetch_confirmation(confirmed_listener, cancelled_listener)
            ui.show_payment_confirmation request.amount
            ui.fetch_confirmation ->(result){
              if result
                confirmed_listener.call
              else
                cancelled_listener.call
              end
            }
          end

          def respond_with_cancelled
            apply_cancelled_response_details
            apply_supported_request_response_details
            respond
          end

          def apply_cancelled_response_details
            set_result '0092', 'ERROR', 'CANCELLED'
          end

          def respond_with_success
            apply_confirmed_response_details
            apply_supported_request_response_details
            respond
          end

          def apply_confirmed_response_details
            set_result '0000', 'APPROVED', 'Approval'
            response.processor_authorization = '1234567'
            response.record_number           = '121212'
            response.reference_data          = '123456789012'
            response.authorized_amount       = total_amount
          end

          def apply_supported_request_response_details
            apply_request_response_passthrough
            apply_fake_client_details
            apply_response_transaction_datetime
            apply_response_receipts
            result_listener.call response
          end

          def apply_confirmed_response_details
            set_result '0000', 'APPROVED', 'Approval'
            response.processor_authorization = '1234567'
            response.record_number           = '121212'
            response.reference_data          = '123456789012'
            response.authorized_amount       = total_amount
          end

          def apply_cancelled_response_details
            set_result '0092', 'ERROR', 'CANCELLED'
          end

          def apply_fake_client_details
            response.merchant_id = '9876543221098'
            response.terminal_id = '12345678'
          end

          def apply_response_transaction_datetime
            now = Time.now
            response.transaction_date = now.strftime('%m%d%y')
            response.transaction_time = now.strftime('%H%M%S')
          end

          def apply_response_receipts
            receipt_assembler = FakePosTerminal::ResultAssemblers::CardSaleReceipt.new( request, response, total_amount )
            response.receipt          = receipt_assembler.call( :merchant)
            response.customer_receipt = receipt_assembler.call( :customer)
          end

        end

      end
    end
  end
end
