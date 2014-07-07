# coding: utf-8

require_relative '../abstract_data'

module ClientForPoslynx
  module Data
    module Responses

      class AbstractResponse < AbstractData

        def self.root_element_name
          ROOT_ELEMENT_NAME
        end

        attr_element_mapping attribute: :result,                   element: 'Result'
        attr_element_mapping attribute: :result_text,              element: 'ResultText'
        attr_element_mapping attribute: :error_code,               element: 'ErrorCode'

      end

    end
  end
end
