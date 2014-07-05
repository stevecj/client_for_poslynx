# coding: utf-8

require 'nokogiri'

module ClientForPoslynx
  module Data

    class CreditCardSaleRequest
      DEFINING_ELEMENT_MAPPINGS = [
        { attribute: :command, element: 'Command' },
      ]

      ATTR_ELEMENT_MAPPINGS = [
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

      def self.defining_element_mappings
        DEFINING_ELEMENT_MAPPINGS
      end

      def self.attr_element_mappings
        ATTR_ELEMENT_MAPPINGS
      end

      def self.xml_deserialize(xml)

        doc = Nokogiri::XML::Document.parse(
          xml,
          nil, nil,
          Nokogiri::XML::ParseOptions::DEFAULT_XML & ~Nokogiri::XML::ParseOptions::RECOVER
        )
        root = doc.at_xpath('/PLRequest')
        raise InvalidXmlContentError, "PLRequest root element not found" unless root
        all_property_texts = root.xpath('./*').group_by{ |el| el.name }.map{ |name, els| [name, els.map(&:text)] }
        repeated_properties = all_property_texts.select{ |name, texts| texts.length > 1 }.map(&:first)
        raise InvalidXmlContentError, "Received multiple instances of property element(s) #{repeated_properties * ', '}" unless repeated_properties.empty?
        property_texts = Hash[
          all_property_texts.map{ |name, texts| [name, texts.first] }
        ]
        instance = new
        defining_element_mappings.each do |mapping|
          attribute, el_name = mapping.values_at(:attribute, :element)
          defining_value = instance.public_send(attribute)
          unless property_texts[el_name] == defining_value
            raise InvalidXmlContentError, "#{el_name} child element with \"#{defining_value}\" value not found"
          end
        end
        defining_element_names = defining_element_mappings.map{ |mapping| mapping[:element] }
        variable_property_texts = property_texts.reject{ |name, text| defining_element_names.include?(name) }
        unrecognized_properties = variable_property_texts.map(&:first) - attr_element_mappings.map{ |mapping| mapping[:element] }
        unless unrecognized_properties.empty?
          raise InvalidXmlContentError, "Received unrecognized child element(s) #{unrecognized_properties * ', '}"
        end
        variable_property_texts.each do |name, text|
          attribute = attr_element_mappings.detect{ |mapping| mapping[:element] == name }[:attribute]
          instance.public_send "#{attribute}=", text
        end
        instance
      rescue Nokogiri::XML::SyntaxError => e
        raise InvalidXmlError
      end

      def all_element_mappings
        self.class.defining_element_mappings + self.class.attr_element_mappings
      end

      def initialize
        self.client_mac = Data::DEFAULT_CLIENT_MAC
      end

      def command
        'CCSALE'
      end

      attr_accessor *attr_element_mappings.map{ |ae| ae[:attribute] }

      def xml_serialize
        doc = Nokogiri::XML::Document.new
        root = doc.create_element('PLRequest')
        all_element_mappings.each do |ae|
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
