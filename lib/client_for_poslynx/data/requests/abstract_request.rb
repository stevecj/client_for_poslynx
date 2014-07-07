# coding: utf-8

require_relative '../abstract_data'

module ClientForPoslynx
  module Data
    module Requests

      class AbstractRequest < AbstractData

        def self.root_element_name
          ROOT_ELEMENT_NAME
        end

        def self.xml_parse(source_xml)
          doc = XmlDocument.new( source_xml )
          data_classes = [
            Data::Requests::CreditCardSale,
            Data::Requests::PinPadInitialize,
          ]
          data_class = data_classes.detect{ |dc| dc.fits_properties?( doc.property_element_values ) }
          data_class.xml_deserialize( source_xml )
        end

        attr_element_mapping attribute: :client_mac,  element: 'ClientMAC'

        def initialize
          self.client_mac = DEFAULT_CLIENT_MAC
        end

      end

    end
  end
end
