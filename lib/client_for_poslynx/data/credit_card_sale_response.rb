# coding: utf-8

require_relative 'abstract_data'

module ClientForPoslynx
  module Data

    class CreditCardSaleResponse < AbstractData
      DEFINING_ELEMENT_MAPPINGS = [
        { attribute: :command, element: 'Command' },
      ]

      ATTR_ELEMENT_MAPPINGS = [
        { attribute: :result,                   element: 'Result'          },
        { attribute: :result_text,              element: 'ResultText'      },
        { attribute: :processor_authorization,  element: 'Authorization'   },
        { attribute: :record_number,            element: 'RecNum'          },
        { attribute: :reference_data,           element: 'RefData'         },
        { attribute: :error_code,               element: 'ErrorCode'       },
        { attribute: :merchant_supplied_id,     element: 'Id'              },
        { attribute: :client_id,                element: 'ClientId'        },
        { attribute: :card_type,                element: 'CardType'        },
        { attribute: :authorized_amount,        element: 'AuthAmt'         },
        { attribute: :card_number_last_4,       element: 'CardNumber'      },
        { attribute: :merchant_id,              element: 'MerchantId'      },
        { attribute: :terminal_id,              element: 'TerminalId'      },
        { attribute: :transaction_date,         element: 'TransactionDate' },
        { attribute: :transaction_time,         element: 'TransactionTime' },
      ]

      class << self

        def defining_element_mappings
          DEFINING_ELEMENT_MAPPINGS
        end

        def attr_element_mappings
          ATTR_ELEMENT_MAPPINGS
        end

        def root_element_name
          'PLResponse'
        end

        def command
          'CCSALE'
        end

      end

      attr_accessor *attr_element_mappings.map{ |ae| ae[:attribute] }

    end

  end
end
