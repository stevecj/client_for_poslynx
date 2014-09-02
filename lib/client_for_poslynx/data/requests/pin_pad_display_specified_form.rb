# coding: utf-8

require_relative 'abstract_request'

module ClientForPoslynx
  module Data
    module Requests

      class PinPadDisplaySpecifiedForm < AbstractRequest

        defining_property_value attribute: :command,   element: 'Command',  value: 'PPSPECIFIEDFORM'

        attr_element_mapping attribute: :form_name,     element: 'FormName'
        attr_element_mapping attribute: :text_values,   element: 'Text',     multi_text: true
        attr_element_mapping attribute: :button_labels, element: 'Buttons',  multi_text: true

      end

    end
  end
end
