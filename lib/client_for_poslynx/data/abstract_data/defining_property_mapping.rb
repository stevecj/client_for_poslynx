# coding: utf-8

module ClientForPoslynx
  module Data
    class AbstractData

      class DefiningPropertyMapping
        attr_reader :attribute_name, :element_name

        def initialize(options)
          @attribute_name = options.fetch(:attribute)
          @element_name = options.fetch(:element)
        end

        def xml_doc_content_from_client_content(client_content)
          client_content
        end
      end

    end
  end
end
