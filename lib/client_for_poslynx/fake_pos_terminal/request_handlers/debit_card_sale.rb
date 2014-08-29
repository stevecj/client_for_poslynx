# coding: utf-8

module ClientForPoslynx
  module FakePosTerminal
    module RequestHandlers

      class DebitCardSale < RequestHandlers::AbstractHandler
        include RequestHandlers::HandlesCardSale

        private

        def new_response
          ClientForPoslynx::Data::Responses::DebitCardSale.new
        end

        def handle_supported_source_request
          response.card_number_last_4 = get_card_swipe
          response.input_method = 'SWIPED'
          confirmed = get_confirmation
          get_customer_pin if confirmed

          # Precidia docs say value is 'OtherCard' for debit, but
          # in practice, found result to be 'Debit' instead.
          response.card_type = 'Debit'

          assemble_supported_source_response confirmed
        end

        def get_customer_pin
          user_interface.show_pin_request
          user_interface.get_fake_pin_entry
          user_interface.show_pin_request clear: false, filled_in: true
          nil
        end

        def total_amount
          '%.2f' % (
            BigDecimal( request.amount ) + BigDecimal( request.cash_back )
          )
        end

        def assemble_request_response_passthrough
          response.merchant_supplied_id = request.merchant_supplied_id
          response.client_id            = request.client_id
          response.amount               = request.amount
          response.cash_back            = request.cash_back
        end

      end

    end
  end
end
