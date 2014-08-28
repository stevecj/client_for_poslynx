# coding: utf-8

require_relative 'abstract_request'

module ClientForPoslynx
  module Data
    module Requests

      class PinPadDisplaySpecifiedForm < AbstractRequest

        defining_element_value attribute: :command,   element: 'Command',  value: 'PPSPECIFIEDFORM'

        attr_element_mapping attribute: :form_name,     element: 'FormName'
        attr_element_mapping attribute: :text_values,   element: 'Text',     type: :array
        attr_element_mapping attribute: :button_labels, element: 'Buttons',  type: :array

      end

    end
  end
end
