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

      def property_element_contents
        @property_element_contents ||= hash_from_element( root )
      end

      private

      attr_reader :nokogiri_doc

      def root
        @root ||= nokogiri_doc.at_xpath("/*")
      end

      def hash_from_element(element)
        all_property_texts = element.xpath('./*')
          .group_by{ |el| el.name }
          .map{ |name, els| [name, els.map { |el| value_from_property_element(el) } ] }
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

      def value_from_property_element(element)
        child_elements = element.xpath('./*')
        if child_elements.length > 0
          hash_from_element( element )
        else
          element.text
        end
      end

    end

  end
end
