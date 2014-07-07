# coding: utf-8

require 'nokogiri'

module ClientForPoslynx
  module Data

    class PropertiesXmlParser
      def self.parse(root_element_name, source_xml)
        new( root_element_name ).parse( source_xml )
      end

      attr_reader :root_element_name

      def initialize(root_element_name)
        @root_element_name = root_element_name
      end

      def parse(source_xml)
        doc = parse_xml(source_xml)
        root = xml_doc_root(doc)
        property_element_values(root)
      end

      def parse_xml(xml)
        Nokogiri::XML::Document.parse(
          xml,
          nil, nil,
          Nokogiri::XML::ParseOptions::DEFAULT_XML & ~Nokogiri::XML::ParseOptions::RECOVER
        )
      rescue Nokogiri::XML::SyntaxError => e
        raise InvalidXmlError
      end

      def xml_doc_root(doc)
        root = doc.at_xpath("/#{root_element_name}")
        raise InvalidXmlContentError, "PLRequest root element not found" unless root
        root
      end

      def property_element_values(root)
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
