# coding: utf-8

require_relative '../format'

module ClientForPoslynx
  module FakePosTerminal
    class RequestHandler

      class VisaReceiptFormatter
        include FakePosTerminal::Format

        attr_reader :request, :response

        def initialize(request, response)
          @request  = request
          @response = response
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
            "ACCOUNT TYPE     Visa                 ",
            "CARD NUMBER      ************%s     " % response.card_number_last_4,
            "DATE/TIME        %s    " % date_time_text,
            "REC #            %-6s               " % response.record_number,
            "REFERENCE #      %-12s S       " % response.reference_data,
            "AMOUNT           %-21s" % amount_usd,
            "                 --------------       ",
            "TOTAL            %-21s" % amount_usd,
            "                 --------------       ",
            "                                      ",
            "%-38s" % status_text,
            "                                      ",
            "IMPORTANT -- retain this copy for your",
            "records.                              ",
            "                                      ",
            "%-38s" % copy_text,
            "                                      ",
          ]
        end

        def amount_usd
          format_usd( request.amount )
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
