# coding: utf-8

require 'nokogiri'

module ClientForPoslynx
  module Data

    class XmlDocument

      class << self
        private :new

        def with_root_element_name(name)
          nokogiri_doc = Nokogiri::XML::Document.new
          nokogiri_doc.root = nokogiri_doc.create_element( name )
          new(nokogiri_doc)
        end

        def from_xml(source_xml)
          nokogiri_doc = Nokogiri::XML::Document.parse(
            source_xml,
            nil, nil,
            Nokogiri::XML::ParseOptions::DEFAULT_XML & ~Nokogiri::XML::ParseOptions::RECOVER
          )
          new(nokogiri_doc)
        rescue Nokogiri::XML::SyntaxError => e
          raise InvalidXmlError
        end

      end

      def initialize(nokogiri_doc)
        @nokogiri_doc = nokogiri_doc
      end

      def verify_root_element_name(expected_name)
        unless root_name == expected_name
          raise InvalidXmlContentError, "#{expected_name} root element not found"
        end
      end

      def serialize
        nokogiri_doc.serialize(
          :save_with => Nokogiri::XML::Node::SaveOptions::AS_XML | Nokogiri::XML::Node::SaveOptions::NO_DECLARATION
        )
      end

      def root_name
        root.name
      end

      def property_element_contents
        @property_element_contents ||= hash_from_element( root )
      end

      def add_property_content(element_name, content)
        element = nokogiri_doc.create_element( element_name )
        if Hash === content
          content.each do |element_name, text|
            child_element = nokogiri_doc.create_element( element_name, nil, nil, text )
            element.add_child child_element
          end
        else
          element.content = content.to_s
        end
        root.add_child element
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
