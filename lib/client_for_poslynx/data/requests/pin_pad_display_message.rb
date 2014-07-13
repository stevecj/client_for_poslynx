# coding: utf-8

require_relative 'abstract_request'

module ClientForPoslynx
  module Data
    module Requests

      class PinPadDisplayMessage < AbstractRequest

        defining_element_value attribute: :command, element: 'Command', value: 'PPDISPLAY'
        attr_element_mapping attribute: :line_count,    element: 'Lines'
        attr_element_mapping attribute: :text_lines,    element: 'Text',    type: :array
        attr_element_mapping attribute: :button_labels, element: 'Buttons', type: :array

      end

    end
  end
end
