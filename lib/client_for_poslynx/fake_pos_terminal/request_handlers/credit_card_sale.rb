# coding: utf-8

module ClientForPoslynx
  module FakePosTerminal
    module RequestHandlers

      class CreditCardSale < RequestHandlers::AbstractHandler
        include RequestHandlers::HandlesCardSale

        private

        def new_response
          ClientForPoslynx::Data::Responses::CreditCardSale.new
        end

        def handle_supported_source_request
          response.card_number_last_4 = get_card_swipe
          response.input_method = 'SWIPED'
          confirmed = get_confirmation
          response.card_type = 'Visa'
          response.signature_image = signature_image if request.capture_signature == 'Yes'
          assemble_supported_source_response confirmed
        end

        def total_amount
          request.amount
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

        def assemble_request_response_passthrough
          response.merchant_supplied_id = request.merchant_supplied_id
          response.client_id            = request.client_id
        end

      end

    end
  end
end
