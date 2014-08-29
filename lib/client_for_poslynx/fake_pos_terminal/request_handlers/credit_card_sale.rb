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
          assemble_supported_source_response confirmed
        end

        def total_amount
          request.amount
        end

        def assemble_request_response_passthrough
          response.merchant_supplied_id = request.merchant_supplied_id
          response.client_id            = request.client_id
        end

      end

    end
  end
end
