# coding: utf-8

require 'nokogiri'

module ClientForPoslynx
  module Data

    class CreditCardSaleRequest
      ATTR_ELEMENTS = [
        { attribute: :merchant_supplied_id,        element: 'Id'           },
        { attribute: :client_id,                   element: 'ClientId'     },
        { attribute: :client_mac,                  element: 'ClientMAC'    },
        { attribute: :tax_amount,                  element: 'TaxAmount'    },
        { attribute: :customer_code,               element: 'CustomerCode' },
        { attribute: :amount,                      element: 'Amount'       },
        { attribute: :input_source,                element: 'Input'        },
        { attribute: :track_2,                     element: 'Track2'       },
        { attribute: :track_1,                     element: 'Track1'       },
        { attribute: :card_number,                 element: 'CardNumber'   },
        { attribute: :expiry_date,                 element: 'ExpiryDate'   },
        { attribute: :address_verification_street, element: 'AVSStreet'    },
        { attribute: :address_verification_zip,    element: 'AVSZip'       },
        { attribute: :card_verification_number,    element: 'CVV'          },
      ]

      def self.attr_elements
        ATTR_ELEMENTS
      end

      attr_accessor *attr_elements.map{ |ae| ae[:attribute] }

      def initialize
        self.client_mac = Data::DEFAULT_CLIENT_MAC
      end

      def xml_serialize
        doc = Nokogiri::XML::Document.new
        root = doc.create_element('PLRequest')
        command_el = doc.create_element('Command', nil, nil, 'CCSALE')
        root.add_child command_el
        self.class.attr_elements.each do |ae|
          content = public_send( ae[:attribute] )
          next unless content
          element = doc.create_element( ae[:element], nil, nil, content )
          root.add_child element
        end
        doc.root = root
        doc.serialize
      end

    end

  end
end
