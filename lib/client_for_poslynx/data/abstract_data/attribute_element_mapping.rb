require 'nokogiri'

module ClientForPoslynx
  module Data
    class AbstractData

      class AttributeElementMapping
        attr_reader :attribute_name, :element_name, :type, :numbered_lines

        def initialize(options)
          @options = options
          @attribute_name = options.fetch(:attribute)
          @element_name = options.fetch(:element)
          @type = options[:type]
          unless type.nil?
            raise ArgumentError, "The :type option must be a symbol, but a #{type.class} was given." unless Symbol === type
            raise ArgumentError, "#{type.inspect} is not a valid :type option. Must be :array when given." unless type == :array
          end
          @numbered_lines = options[:numbered_lines]
        end

        def value_from_element_content(content)
          if numbered_lines
            template = numbered_lines
            [].tap{ |lines|
              line_num = 1
              while ( content.has_key?(key = template % line_num) )
                lines << content[key]
                line_num += 1
              end
            }
          elsif type == :array
            content.split('|')
          else
            content
          end
        end

        def xml_doc_content_from_client_content(client_content)
          if numbered_lines
            xml_numbered_lines_from_client_content( client_content )
          elsif type == :array
            xml_multi_text_from_client_content( client_content )
          else
            client_content.to_s
          end
        end

        private

        def xml_numbered_lines_from_client_content(client_content)
          client_content = [client_content].flatten
          template = numbered_lines
          Hash[
            client_content.each_with_index.map { |line_text, idx|
              line_num = idx + 1
              line_element_name = template % line_num
              [ line_element_name, line_text ]
            }
          ]
        end

        def xml_multi_text_from_client_content(client_content)
          client_content = [client_content].flatten
          client_content * '|'
        end

      end

    end
  end
end
