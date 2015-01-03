# coding: utf-8

module ClientForPoslynx
  module FakePosTerminal
    class ConsoleUserInterface
      module RequestProcessors

        class DebitCardSaleProcessor < AbstractProcessor
          include ProcessesCardSale

          def call
            request.cash_back = '0.00' if "#{request.cash_back}".strip.empty?

            fetch_card_swipe ->() {
              fetch_sale_confirmation(
                ->() {
                  fetch_pin method(:respond_with_success)
                },
                method( :respond_with_cancelled )
              )
            }
          end

          def use_card_type
            # Precidia docs say value is 'OtherCard' for debit, but
            # in practice, found result to be 'Debit' instead.
            'Debit'
          end

          def total_amount
            '%.2f' % (
              BigDecimal( request.amount ) + BigDecimal( request.cash_back )
            )
          end

          def apply_request_response_passthrough
            response.merchant_supplied_id = request.merchant_supplied_id
            response.client_id            = request.client_id
            response.amount               = request.amount
            response.cash_back            = request.cash_back
          end

          def fetch_pin(after)
            show_pin_request
            fetch_fake_pin_entry ->() {
              show_pin_request filled_in: true
              after.call
            }
          end

          def fetch_fake_pin_entry(after)
            puts
            print "Press enter to pretend to enter a PIN: "
            save_cursor_position
            UserRawTextLineFetcher.new(
              ui_context,
              ->(entry) { true },
              ->(entry) {
                after.call
              }
            ).call
          end

          def show_pin_request(options = {})
            show_as_filled_in = options.fetch(:filled_in){ false }
            input_box = show_as_filled_in ? '[ * * * * ]' : '[ _ _ _ _ ]'
            content = content_fmt.multiline_message( [
              'Please enter your PIN...',
              input_box
            ])
            display_content content, options
          end

        end

      end
    end
  end
end
