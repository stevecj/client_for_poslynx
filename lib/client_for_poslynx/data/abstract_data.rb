# coding: utf-8

require_relative 'abstract_data/attribute_element_mapping'
require_relative 'abstract_data/defining_property_mapping'

module ClientForPoslynx
  module Data

    class AbstractData

      class << self

        alias blank_new new

        def new
          blank_new
        end

        def short_name
          name.split( '::' ).last
        end

        def xml_parse(source_xml)
          doc = XmlDocument.from_xml( source_xml )
          data_class = concrete_data_class_for_nokogiri_document( doc )
          data_class.xml_deserialize( source_xml )
        end

        def xml_deserialize(xml)
          doc = XmlDocument.from_xml( xml )
          doc.verify_root_element_name root_element_name
          instance = load_from_properties( doc.property_element_contents )
          instance.source_data = xml
          instance
        end

        def load_from_properties(property_contents)
          verify_defining_properties property_contents
          variable_property_contents = select_variable_property_contents(property_contents)
          instance = blank_new
          populate_instance_from_properties instance, variable_property_contents
          instance
        end

        def fits_properties?(property_contents)
          unmatched = unmatched_defining_properties( property_contents )
          unmatched.empty?
        end

        def defining_property_mappings
          @defining_property_mappings ||= (
            self == AbstractData ?
              [] :
              superclass.defining_property_mappings + []
          )
        end

        def attr_element_mappings
          @attr_element_mappings ||= (
            self == AbstractData ?
              [] :
              superclass.attr_element_mappings + []
          )
        end

        private

        def inherited(descendant)
          descendants << descendant
        end

        def descendants
          @@descendants ||= []
        end

        def concrete_data_class_for_nokogiri_document(doc)
          data_class = concrete_data_classes.detect{ |dc|
            dc.root_element_name == doc.root_name &&
            dc.fits_properties?( doc.property_element_contents )
          }
        end

        def concrete_data_classes
          descendants.
            reject{ |d| d.name =~ /\bAbstract[A-Z]\w*$/ }.
            sort_by{ |d| -d.ancestors.length }
        end

        def defining_property_value(options)
          attribute = options.fetch( :attribute )
          element   = options.fetch( :element   )
          value     = options.fetch( :value     )
          define_singleton_method( attribute ) { value }
          define_method( attribute ) { value }
          defining_property_mappings << DefiningPropertyMapping.new( attribute: attribute, element: element )
        end

        def attr_element_mapping(options)
          mapping = AbstractData::AttributeElementMapping.new( options )
          attr_element_mappings << mapping
          attr_accessor mapping.attribute_name
        end

        def verify_defining_properties(property_contents)
          unmatched = unmatched_defining_properties( property_contents )
          return if unmatched.empty?
          message = unmatched.map{ |property_mapping|
            defining_mapping = public_send( property_mapping.attribute_name )
            "#{property_mapping.element_name} child element with \"#{defining_mapping}\" value not found."
          }.join( ' ' )
          raise InvalidXmlContentError, message
        end

        def unmatched_defining_properties(property_contents)
          unmatched = []
          defining_property_mappings.each do |property_mapping|
            defining_value = public_send( property_mapping.attribute_name )
            unmatched << property_mapping unless property_contents[property_mapping.element_name] == defining_value
          end
          unmatched
        end

        def select_variable_property_contents(property_contents)
          defining_element_names = defining_property_mappings.map(&:element_name)
          property_contents.reject{ |name, content| defining_element_names.include?(name) }
        end

        def populate_instance_from_properties instance, variable_property_contents
          variable_property_contents.each do |name, content|
            mapping = attr_element_mappings.detect{ |mapping| mapping.element_name == name }
            next unless mapping
            instance.public_send "#{mapping.attribute_name}=", mapping.value_from_element_content( content)
          end
        end

      end

      attr_accessor :source_data

      def xml_serialize
        doc = Data::XmlDocument.with_root_element_name( self.class.root_element_name )
        add_properties_to_xml_document doc
        doc.serialize
      end

      private

      def add_properties_to_xml_document(doc)
        all_mappings.each do |mapping|
          content = property_attribute_value( mapping )
          next unless content
          doc_content = mapping.xml_doc_content_from_client_content( content )
          doc.add_property_content mapping.element_name, doc_content
        end
      end

      def all_mappings
        self.class.defining_property_mappings + self.class.attr_element_mappings
      end

      def property_attribute_value( property )
        public_send( property.attribute_name )
      end

    end

  end
end
