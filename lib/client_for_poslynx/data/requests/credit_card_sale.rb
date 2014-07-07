# coding: utf-8

require_relative '../abstract_data'

module ClientForPoslynx
  module Data
    module Requests

      class CreditCardSale < AbstractData
        defining_element_value attribute: :command, element: 'Command', value: 'CCSALE'

        attr_element_mapping attribute: :merchant_supplied_id, element: 'Id'
        attr_element_mapping attribute: :client_id,            element: 'ClientId'
        attr_element_mapping attribute: :client_mac,           element: 'ClientMAC'
        attr_element_mapping attribute: :tax_amount,           element: 'TaxAmount'
        attr_element_mapping attribute: :customer_code,        element: 'CustomerCode'
        attr_element_mapping attribute: :amount,               element: 'Amount'
        attr_element_mapping attribute: :input_source,         element: 'Input'
        attr_element_mapping attribute: :track_2,              element: 'Track2'
        attr_element_mapping attribute: :track_1,              element: 'Track1'
        attr_element_mapping attribute: :card_number,          element: 'CardNumber'
        attr_element_mapping attribute: :expiry_date,          element: 'ExpiryDate'

        def self.root_element_name
          'PLRequest'
        end

        def initialize
          self.client_mac = Data::DEFAULT_CLIENT_MAC
        end

      end

    end
  end
end
