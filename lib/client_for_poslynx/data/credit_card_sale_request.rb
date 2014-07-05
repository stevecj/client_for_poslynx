# coding: utf-8

require 'nokogiri'

module ClientForPoslynx
  module Data

    class CreditCardSaleRequest

      def xml_serialize
        doc = Nokogiri::XML::Document.new
        root = doc.create_element('PLRequest')
        command_el = doc.create_element('Command', nil, nil, 'CCSALE')
        root.add_child command_el
        doc.root = root
        doc.serialize
      end

    end

  end
end
