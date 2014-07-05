# coding: utf-8

require 'nokogiri'

module ClientForPoslynx
  module Data

    class AbstractData

      class << self

        def xml_deserialize(xml)
          doc = parse_xml(xml)
          root = xml_doc_root(doc)
          property_values = property_element_values(root)
          verify_defining_properties property_values
          variable_property_values = variable_property_values(property_values)
          instance = new
          instance.source_data = xml
          populate_instance_from_xml_properties instance, variable_property_values
          instance
        end

        private

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
          all_property_texts = root.xpath('./*').group_by{ |el| el.name }.map{ |name, els| [name, els.map(&:text)] }
          repeated_properties = all_property_texts.select{ |name, texts| texts.length > 1 }.map(&:first)
          raise InvalidXmlContentError, "Received multiple instances of property element(s) #{repeated_properties * ', '}" unless repeated_properties.empty?
          Hash[
            all_property_texts.map{ |name, texts| [name, texts.first] }
          ]
        end

        def verify_defining_properties(property_values)
          defining_element_mappings.each do |mapping|
            attribute, el_name = mapping.values_at(:attribute, :element)
            defining_value = public_send(attribute)
            unless property_values[el_name] == defining_value
              raise InvalidXmlContentError, "#{el_name} child element with \"#{defining_value}\" value not found"
            end
          end
        end

        def variable_property_values(property_values)
          defining_element_names = defining_element_mappings.map{ |mapping| mapping[:element] }
          property_values.reject{ |name, text| defining_element_names.include?(name) }
        end

        def populate_instance_from_xml_properties instance, variable_property_values
          variable_property_values.each do |name, text|
            mapping = attr_element_mappings.detect{ |mapping| mapping[:element] == name }
            next unless mapping
            attribute = mapping[:attribute]
            instance.public_send "#{attribute}=", text
          end
        end

      end

      attr_accessor :source_data

      def xml_serialize
        doc = Nokogiri::XML::Document.new
        root = doc.create_element(self.class.root_element_name)
        self.class.defining_element_mappings.each do |ae|
          content = self.class.public_send( ae[:attribute] )
          next unless content
          element = doc.create_element( ae[:element], nil, nil, content )
          root.add_child element
        end
        self.class.attr_element_mappings.each do |ae|
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
