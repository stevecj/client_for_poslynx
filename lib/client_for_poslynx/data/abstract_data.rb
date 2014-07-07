# coding: utf-8

require 'nokogiri'

module ClientForPoslynx
  module Data

    class AbstractData

      class << self

        def xml_parse(source_xml)
          doc = XmlDocument.new( source_xml )
          concrete_data_classes = descendants.
            reject{ |d| d.name =~ /\bAbstract[A-Z]\w*$/ }.
            sort_by{ |d| -d.ancestors.length }
          data_class = concrete_data_classes.detect{ |dc|
            dc.root_element_name == doc.root_name &&
            dc.fits_properties?( doc.property_element_values )
          }
          data_class.xml_deserialize(source_xml)
        end

        def xml_deserialize(xml)
          doc = XmlDocument.new(xml)
          raise InvalidXmlContentError, "#{root_element_name} root element not found" unless doc.root_name == root_element_name
          instance = load_from_properties doc.property_element_values
          instance.source_data = doc.source_xml
          instance
        end

        def load_from_properties(property_values)
          verify_defining_properties property_values
          variable_property_values = variable_property_values(property_values)
          instance = new
          populate_instance_from_properties instance, variable_property_values
          instance
        end

        def fits_properties?(property_values)
          unmatched = unmatched_defining_properties( property_values )
          unmatched.empty?
        end

        def defining_element_mappings
          @defining_element_mappings ||=
            begin
              self == AbstractData ?
                [] :
                superclass.defining_element_mappings + []
            end
        end

        def attr_element_mappings
          @attr_element_mappings ||=
            begin
              self == AbstractData ?
                [] :
                superclass.attr_element_mappings + []
            end
        end

        private

        def inherited(descendant)
          descendants << descendant
        end

        def descendants
          @@descendants ||= []
        end

        def defining_element_value(options)
          attribute = options.fetch( :attribute )
          element   = options.fetch( :element   )
          value     = options.fetch( :value     )
          define_singleton_method(attribute) { value }
          defining_element_mappings << { attribute: attribute, element: element }
        end

        def attr_element_mapping(options)
          attribute = options.fetch( :attribute )
          element   = options.fetch( :element   )
          attr_accessor attribute
          attr_element_mappings << options
        end

        def verify_defining_properties(property_values)
          unmatched = unmatched_defining_properties(property_values)
          return if unmatched.empty?
          message = unmatched.map{ |mapping|
            attribute, el_name = mapping.values_at(:attribute, :element)
            defining_value = public_send(attribute)
            "#{el_name} child element with \"#{defining_value}\" value not found."
          }.join( ' ' )
          raise InvalidXmlContentError, message
        end

        def unmatched_defining_properties(property_values)
          unmatched = []
          defining_element_mappings.each do |mapping|
            attribute, el_name = mapping.values_at(:attribute, :element)
            defining_value = public_send(attribute)
            unmatched << mapping unless property_values[el_name] == defining_value
          end
          unmatched
        end

        def variable_property_values(property_values)
          defining_element_names = defining_element_mappings.map{ |mapping| mapping[:element] }
          property_values.reject{ |name, text| defining_element_names.include?(name) }
        end

        def populate_instance_from_properties instance, variable_property_values
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
