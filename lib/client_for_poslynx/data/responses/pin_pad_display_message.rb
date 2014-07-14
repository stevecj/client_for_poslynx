# coding: utf-8

require_relative 'abstract_response'

module ClientForPoslynx
  module Data
    module Responses

      class PinPadDisplayMessage < AbstractResponse

        defining_element_value attribute: :command, element: 'Command', value: 'PPDISPLAY'
        attr_element_mapping attribute: :button_response,  element: 'Response'

      end

    end
  end
end
