# coding: utf-8

require 'nokogiri'

module ClientForPoslynx
  module Data

    class AbstractData

      class << self

        alias blank_new new

        def new
          blank_new
        end

        def xml_parse(source_xml)
          doc = XmlDocument.new( source_xml )
          concrete_data_classes = descendants.
            reject{ |d| d.name =~ /\bAbstract[A-Z]\w*$/ }.
            sort_by{ |d| -d.ancestors.length }
          data_class = concrete_data_classes.detect{ |dc|
            dc.root_element_name == doc.root_name &&
            dc.fits_properties?( doc.property_element_contents )
          }
          data_class.xml_deserialize(source_xml)
        end

        def xml_deserialize(xml)
          doc = XmlDocument.new(xml)
          raise InvalidXmlContentError, "#{root_element_name} root element not found" unless doc.root_name == root_element_name
          instance = load_from_properties( doc.property_element_contents )
          instance.source_data = doc.source_xml
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
          type = options[:type]
          unless type.nil?
            raise ArgumentError, "The :type option must be a symbol, but a #{type.class} was given." unless Symbol === type
            raise ArgumentError, "#{type.inspect} is not a valid :type option. Must be :array when given." unless type == :array
          end
          attribute = options.fetch( :attribute )
          element   = options.fetch( :element   )
          attr_accessor attribute
          attr_element_mappings << options
        end

        def verify_defining_properties(property_contents)
          unmatched = unmatched_defining_properties( property_contents )
          return if unmatched.empty?
          message = unmatched.map{ |mapping|
            attribute, el_name = mapping.values_at(:attribute, :element)
            defining_value = public_send(attribute)
            "#{el_name} child element with \"#{defining_value}\" value not found."
          }.join( ' ' )
          raise InvalidXmlContentError, message
        end

        def unmatched_defining_properties(property_contents)
          unmatched = []
          defining_element_mappings.each do |mapping|
            attribute, el_name = mapping.values_at(:attribute, :element)
            defining_value = public_send(attribute)
            unmatched << mapping unless property_contents[el_name] == defining_value
          end
          unmatched
        end

        def select_variable_property_contents(property_contents)
          defining_element_names = defining_element_mappings.map{ |mapping| mapping[:element] }
          property_contents.reject{ |name, content| defining_element_names.include?(name) }
        end

        def populate_instance_from_properties instance, variable_property_contents
          variable_property_contents.each do |name, content|
            mapping = attr_element_mappings.detect{ |mapping| mapping[:element] == name }
            next unless mapping
            value = if mapping[:numbered_lines]
              template = mapping[:numbered_lines]
              [].tap{ |lines|
                line_num = 1
                while ( content.has_key?(key = template % line_num) )
                  lines << content[key]
                  line_num += 1
                end
              }
            elsif mapping[:type] == :array
              content.split('|')
            else
              content
            end
            attribute = mapping[:attribute]
            instance.public_send "#{attribute}=", value
          end
        end

      end

      attr_accessor :source_data

      def xml_serialize
        doc = Nokogiri::XML::Document.new
        root = doc.create_element(self.class.root_element_name)
        self.class.defining_element_mappings.each do |mapping|
          content = self.class.public_send( mapping[:attribute] )
          next unless content
          element = doc.create_element( mapping[:element], nil, nil, content )
          root.add_child element
        end
        self.class.attr_element_mappings.each do |mapping|
          content = public_send( mapping[:attribute] )
          next unless content
          element = if mapping[:numbered_lines]
            build_numbered_lines_xml_node( doc, mapping[:element], mapping[:numbered_lines], content )
          elsif mapping[:type] == :array
            build_vertical_bar_separated_list_node( doc, mapping[:element], content )
          else
            build_text_element_node( doc, mapping[:element], content )
          end
          root.add_child element
        end
        doc.root = root
        doc.serialize(:save_with => Nokogiri::XML::Node::SaveOptions::AS_XML | Nokogiri::XML::Node::SaveOptions::NO_DECLARATION)
      end

      private

      def build_numbered_lines_xml_node(doc, element_name, line_template, content)
        element = doc.create_element( element_name )
        [content].flatten.each_with_index do |line_text, idx|
          line_num = idx + 1
          element_name = line_template % line_num
          line_el = doc.create_element( element_name, nil, nil, line_text )
          element.add_child line_el
        end
        element
      end

      def build_vertical_bar_separated_list_node(doc, element_name, content)
        text = [content].flatten * '|'
        doc.create_element( element_name, nil, nil, text )
      end

      def build_text_element_node(doc, element_name, content)
        doc.create_element( element_name, nil, nil, "#{content}" )
      end

    end

  end
end
