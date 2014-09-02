# coding: utf-8

require 'nokogiri'

module ClientForPoslynx
  module Data
    class AbstractData

      module AttributeElementMapping

        class Abstract ; end
        class Text          < AttributeElementMapping::Abstract ; end
        class MultiText     < AttributeElementMapping::Abstract ; end
        class NumberedLines < AttributeElementMapping::Abstract ; end

        def self.new(options)
          klass = case
            when options[:multi_text]     ; AttributeElementMapping::MultiText
            when options[:numbered_lines] ; AttributeElementMapping::NumberedLines
            else                          ; AttributeElementMapping::Text
          end
          klass.new( options )
        end

        class Abstract
          attr_reader :attribute_name, :element_name, :numbered_line_template

          def numbered_lines? ; @numbered_lines ; end
          def multi_text?     ; @multi_text     ; end

          def initialize(options)
            options = options.reject { |k,v| v.nil? }
            @attribute_name = options.fetch( :attribute ) { raise ArgumentError, ':attribute option value must be provided' }
            @element_name   = options.fetch( :element   ) { raise ArgumentError, ':element option value must be provided' }
            options.delete :attribute ; options.delete :element
            additional_init options
            verify_no_unexpected_unused_options options
          end

          def text_mapping?           ; false ; end
          def multi_text_mapping?     ; false ; end
          def numbered_lines_mapping? ; false ; end

          def value_from_element_content(content)
            raise NotImplementedError
            [].tap{ |lines|
              line_num = 1
              while ( content.has_key?(key =  numbered_line_template % line_num) )
                lines << content[key]
                line_num += 1
              end
            }
          end

          def xml_doc_content_from_client_content(client_content)
            raise NotImplementedError
          end

          private

          def verify_no_unexpected_unused_options(unused_options)
            unless unused_options.empty?
              key_list = unused_options.keys.map(&:inspect)
              raise ArgumentError, "Unexpected option(s) #{key_list} supplied"
            end
          end

          def additional_init(options)
            # Do nothing by default.
          end
        end

        class Text < AttributeElementMapping::Abstract
          def text_mapping? ; true ; end

          def value_from_element_content(content)
            content
          end

          def xml_doc_content_from_client_content(client_content)
            client_content.to_s
          end
        end

        class MultiText < AttributeElementMapping::Abstract
          def multi_text_mapping? ; true ; end

          def value_from_element_content(content)
            content.split('|')
          end

          def xml_doc_content_from_client_content(client_content)
            client_content = [client_content].flatten
            client_content * '|'
          end

          private

          def additional_init(options)
            @multi_text = !!options.delete( :multi_text )
          end
        end

        class NumberedLines < AttributeElementMapping::Abstract
          def numbered_lines_mapping? ; true ; end

          def value_from_element_content(content)
            [].tap{ |lines|
              line_num = 1
              while ( content.has_key?(key =  numbered_line_template % line_num) )
                lines << content[key]
                line_num += 1
              end
            }
          end

          def xml_doc_content_from_client_content(client_content)
            client_content = [client_content].flatten
            Hash[
              client_content.each_with_index.map { |line_text, idx|
                line_num = idx + 1
                line_element_name = numbered_line_template % line_num
                [ line_element_name, line_text ]
              }
            ]
          end

          private

          def additional_init(options)
            numbered_line_name_template = options.delete( :numbered_lines )
            @numbered_lines = !!numbered_line_name_template
            @numbered_line_template = numbered_line_name_template
          end
        end

      end

    end
  end
end
