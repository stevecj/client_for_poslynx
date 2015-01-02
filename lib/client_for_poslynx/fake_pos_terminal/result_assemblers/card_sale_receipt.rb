# coding: utf-8

module ClientForPoslynx
  module FakePosTerminal
    module ResultAssemblers

      class CardSaleReceipt
        include FakePosTerminal::ValueFormatting

        attr_reader :request, :response, :total_amount

        def initialize(request, response, total_amount)
          @request      = request
          @response     = response
          @total_amount = total_amount
        end

        def call(copy)
          copy_text = ('%s COPY' % copy).upcase
          [
            "Fancy Dancy Place                     ",
            "1313 Mockingbird Lane Kanata, ON      ",
            "Canada                                ",
            "(613)542-6019                         ",
            "                                      ",
            "TYPE             PURCHASE             ",
            "ACCOUNT TYPE     %-21s" % response.card_type,
            "CARD NUMBER      ************%s     " % response.card_number_last_4,
            "DATE/TIME        %s    " % date_time_text,
            "REC #            %-6s               " % response.record_number,
            "REFERENCE #      %-12s S       " % response.reference_data,
            "AMOUNT           %-21s" % amount_usd,
            cash_back_line,
            "                 --------------       ",
            "TOTAL            %-21s" % total_amount_usd,
            "                 --------------       ",
            "                                      ",
            "%-38s" % status_text,
            "                                      ",
            "IMPORTANT -- retain this copy for your",
            "records.                              ",
            "                                      ",
            "%-38s" % copy_text,
            "                                      ",
          ].compact
        end

        def cash_back_line
          return nil unless cash_back_applicable?
          "CASH BACK        %-21s" % cash_back_usd
        end

        def amount_usd
          format_usd( request.amount )
        end

        def total_amount_usd
          format_usd( total_amount )
        end

        def cash_back_applicable?
          request.respond_to?(:cash_back)
        end

        def cash_back_usd
          format_usd( request.cash_back )
        end

        def status_text
          response.error_code == '0000' ?
            'APPROVED - THANK YOU' :
            'TRANSACTION CANCELED'
        end

        def date_time_text
          td = response.transaction_date
          tt = response.transaction_time
          '%s/%s/%s %s:%s:%s' % [
            td[0..1], td[2..3], td[4..5],
            tt[0..1], tt[2..3], tt[4..5],
          ]
        end

      end

    end
  end
end
