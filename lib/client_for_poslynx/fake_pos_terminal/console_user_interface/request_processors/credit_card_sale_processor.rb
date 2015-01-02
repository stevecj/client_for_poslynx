# coding: utf-8

module ClientForPoslynx
  module FakePosTerminal
    class ConsoleUserInterface
      module RequestProcessors

        class CreditCardSaleProcessor < AbstractProcessor
          include ProcessesCardSale

          def call
            fetch_card_swipe ->() {
              fetch_confirmation(
                ->() {
                  if request.capture_signature == 'Yes'
                    fetch_signature method(:respond_with_success)
                  else
                    respond_with_success
                  end
                },
                method( :respond_with_cancelled )
              )
            }
          end

          def use_card_type
            'Visa'
          end

          def total_amount
            request.amount
          end

          def apply_request_response_passthrough
            response.merchant_supplied_id = request.merchant_supplied_id
            response.client_id            = request.client_id
          end

          def fetch_signature(after)
            ui.display_signature_entry_box
            puts
            print "Press enter to simulate entering a signature: "
            UserRawTextLineFetcher.new(
              ui,
              ->(entry) { true },
              ->(entry) {
                apply_signature_image_data
                respond_with_success
              }
            ).call
          end

          def apply_signature_image_data
            response.signature_image = signature_image
          end

          def signature_image
            SignatureImage.new.tap { |si|
              si.metrics = SignatureImage::Metrics.new( [2048, 256], [20_000, 2_500] )

              # Say "Hi"

              si.move 40, 40
              si.draw -5, 30
              si.draw -5, 30

              si.move 70, 40
              si.draw -5, 30
              si.draw -5, 30

              si.move 35, 70
              si.draw 30,  0


              si.move 80, 70
              si.draw -5, 30

              si.move 81, 64
            }
          end

        end

      end
    end
  end
end
