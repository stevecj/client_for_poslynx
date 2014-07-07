# coding: utf-8

require_relative '../abstract_data'

module ClientForPoslynx
  module Data
    module Requests

      module XmlParser
        extend self

        def xml_parse(source_xml)
          property_values = Data::PropertiesXmlParser.parse( 'PLRequest', source_xml )
          data_classes = [
            Data::Requests::CreditCardSale,
            Data::Requests::PinPadReset,
          ]
          data_class = data_classes.detect{ |dc| dc.fits_properties?( property_values ) }
          data_class.xml_deserialize(source_xml)
        end

      end

    end
  end
end
