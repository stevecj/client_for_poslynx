# coding: utf-8

module ClientForPoslynx
  module FakePosTerminal
    class ConsoleUserInterface
      module RequestProcessors

        module ProcessesCardSale
          private

          def fetch_card_swipe(after)
            show_card_swipe_request
            fetch_fake_card_swipe_entry ->(last_4_digits){
              response.card_number_last_4 = last_4_digits
              response.input_method = 'SWIPED'
              response.card_type    = use_card_type
              after.call
            }
          end

          def fetch_fake_card_swipe_entry(result_listener)
            puts
            print "Enter last 4 digits of hypothetical swiped card: "
            UserTextLineFetcher.new(
              ui_context,
              /\A\d{4}\Z/.method(:match),
              result_listener
            ).call
          end

          def show_card_swipe_request
            display_content content_fmt.card_swipe_request(request)
          end

          def show_payment_confirmation(amount)
            content =
              content_fmt.payment_confirmation( amount ) <<
              content_fmt.buttons(%w[ OK Cancel ])
            display_content content
          end

          def fetch_sale_confirmation(confirmed_listener, cancelled_listener)
            show_payment_confirmation request.amount
            fetch_confirmation ->(result){
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
