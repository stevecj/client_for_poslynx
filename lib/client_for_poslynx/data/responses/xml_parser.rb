# coding: utf-8

require_relative '../abstract_data'

module ClientForPoslynx
  module Data
    module Responses

      module XmlParser
        extend self

        def xml_parse(source_xml)
          property_values = Data::PropertiesXmlParser.parse( 'PLResponse', source_xml )
          data_classes = [
            Data::Responses::CreditCardSale,
            Data::Responses::PinPadInitialize,
          ]
          data_class = data_classes.detect{ |dc| dc.fits_properties?( property_values ) }
          data_class.xml_deserialize(source_xml)
        end

      end

    end
  end
end
