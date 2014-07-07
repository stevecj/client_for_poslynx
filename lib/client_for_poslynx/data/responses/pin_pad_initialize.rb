# coding: utf-8

require_relative '../abstract_data'

module ClientForPoslynx
  module Data
    module Responses

      class PinPadInitialize < AbstractData
        defining_element_value attribute: :command, element: 'Command', value: 'PPINIT'

        attr_element_mapping attribute: :result,                   element: 'Result'
        attr_element_mapping attribute: :result_text,              element: 'ResultText'
        attr_element_mapping attribute: :error_code,               element: 'ErrorCode'

        def self.root_element_name
          'PLResponse'
        end

      end

    end
  end
end
