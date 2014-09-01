# coding: utf-8

require_relative 'abstract_response'

module ClientForPoslynx
  module Data
    module Responses

      class PinPadDisplaySpecifiedForm < AbstractResponse

        defining_property_value attribute: :command, element: 'Command', value: 'PPSPECIFIEDFORM'
        attr_element_mapping attribute: :button_response,  element: 'Response'
        attr_element_mapping attribute: :signature_data,  element: 'Signature'

      end

    end
  end
end
