# coding: utf-8

require_relative 'abstract_response'

module ClientForPoslynx
  module Data
    module Responses

      class CreditCardSale < AbstractResponse

        defining_element_value attribute: :command, element: 'Command', value: 'CCSALE'

        attr_element_mapping attribute: :processor_authorization,  element: 'Authorization'
        attr_element_mapping attribute: :record_number,            element: 'RecNum'
        attr_element_mapping attribute: :reference_data,           element: 'RefData'
        attr_element_mapping attribute: :merchant_supplied_id,     element: 'Id'
        attr_element_mapping attribute: :client_id,                element: 'ClientId'
        attr_element_mapping attribute: :card_type,                element: 'CardType'
        attr_element_mapping attribute: :authorized_amount,        element: 'AuthAmt'
        attr_element_mapping attribute: :card_number_last_4,       element: 'CardNumber'
        attr_element_mapping attribute: :merchant_id,              element: 'MerchantId'
        attr_element_mapping attribute: :terminal_id,              element: 'TerminalId'
        attr_element_mapping attribute: :transaction_date,         element: 'TransactionDate'
        attr_element_mapping attribute: :transaction_time,         element: 'TransactionTime'

      end

    end
  end
end
