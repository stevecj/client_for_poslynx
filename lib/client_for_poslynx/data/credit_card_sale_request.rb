# coding: utf-8

require_relative 'abstract_data'

module ClientForPoslynx
  module Data

    class CreditCardSaleRequest < AbstractData
      DEFINING_ELEMENT_MAPPINGS = [
        { attribute: :command, element: 'Command' },
      ]

      ATTR_ELEMENT_MAPPINGS = [
        { attribute: :merchant_supplied_id, element: 'Id'           },
        { attribute: :client_id,            element: 'ClientId'     },
        { attribute: :client_mac,           element: 'ClientMAC'    },
        { attribute: :tax_amount,           element: 'TaxAmount'    },
        { attribute: :customer_code,        element: 'CustomerCode' },
        { attribute: :amount,               element: 'Amount'       },
        { attribute: :input_source,         element: 'Input'        },
        { attribute: :track_2,              element: 'Track2'       },
        { attribute: :track_1,              element: 'Track1'       },
        { attribute: :card_number,          element: 'CardNumber'   },
        { attribute: :expiry_date,          element: 'ExpiryDate'   },
      ]

      def self.defining_element_mappings
        DEFINING_ELEMENT_MAPPINGS
      end

      def self.attr_element_mappings
        ATTR_ELEMENT_MAPPINGS
      end

      def self.root_element_name
        'PLRequest'
      end

      def self.command
        'CCSALE'
      end

      attr_accessor *attr_element_mappings.map{ |ae| ae[:attribute] }

      def initialize
        self.client_mac = Data::DEFAULT_CLIENT_MAC
      end

    end

  end
end
