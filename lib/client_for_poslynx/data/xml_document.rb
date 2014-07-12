# coding: utf-8

require 'nokogiri'

module ClientForPoslynx
  module Data

    class XmlDocument

      attr_reader :source_xml

      def initialize( source_xml )
        @source_xml = source_xml
        @nokogiri_doc = Nokogiri::XML::Document.parse(
          source_xml,
          nil, nil,
          Nokogiri::XML::ParseOptions::DEFAULT_XML & ~Nokogiri::XML::ParseOptions::RECOVER
        )
      rescue Nokogiri::XML::SyntaxError => e
        p e
        raise InvalidXmlError
      end

      def root_name
        root.name
      end

      def property_element_values
        @property_element_values ||= _property_element_values
      end

      private

      attr_reader :nokogiri_doc

      def root
        @root ||= nokogiri_doc.at_xpath("/*")
      end

      def _property_element_values
        all_property_texts = root.xpath('./*')
          .group_by{ |el| el.name }
          .map{ |name, els| [name, els.map(&:text)] }
        repeated_properties = all_property_texts
          .select{ |name, texts| texts.length > 1 }
          .map(&:first)
        unless repeated_properties.empty?
          raise InvalidXmlContentError,
            "Received multiple instances of property element(s) #{repeated_properties * ', '}"
        end
        Hash[
          all_property_texts.map{ |name, texts| [name, texts.first] }
        ]
      end

    end

  end
end
