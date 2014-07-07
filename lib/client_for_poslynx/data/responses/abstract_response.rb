# coding: utf-8

require_relative '../abstract_data'

module ClientForPoslynx
  module Data
    module Responses

      class AbstractResponse < AbstractData

        def self.root_element_name
          ROOT_ELEMENT_NAME
        end

        attr_element_mapping attribute: :result,                   element: 'Result'
        attr_element_mapping attribute: :result_text,              element: 'ResultText'
        attr_element_mapping attribute: :error_code,               element: 'ErrorCode'

        def self.xml_parse(source_xml)
          doc = XmlDocument.new( source_xml )
          data_classes = [
            Data::Responses::CreditCardSale,
            Data::Responses::PinPadInitialize,
          ]
          data_class = data_classes.detect{ |dc| dc.fits_properties?( doc.property_element_values ) }
          data_class.xml_deserialize(source_xml)
        end

      end

    end
  end
end
