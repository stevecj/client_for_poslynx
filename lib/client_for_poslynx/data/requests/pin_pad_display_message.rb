# coding: utf-8

require_relative 'abstract_request'

module ClientForPoslynx
  module Data
    module Requests

      class PinPadDisplayMessage < AbstractRequest

        defining_property_value attribute: :command, element: 'Command', value: 'PPDISPLAY'
        attr_element_mapping attribute: :line_count,    element: 'Lines'
        attr_element_mapping attribute: :text_lines,    element: 'Text',    multi_text: true
        attr_element_mapping attribute: :button_labels, element: 'Buttons', multi_text: true

      end

    end
  end
end
