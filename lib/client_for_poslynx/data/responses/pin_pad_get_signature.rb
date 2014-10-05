# coding: utf-8

require_relative 'abstract_response'

module ClientForPoslynx
  module Data
    module Responses

      class PinPadGetSignature < AbstractResponse

        defining_property_value attribute: :command, element: 'Command', value: 'PPGETSIGNATURE'
        attr_element_mapping attribute: :signature,  element: 'Signature'

      end

    end
  end
end
