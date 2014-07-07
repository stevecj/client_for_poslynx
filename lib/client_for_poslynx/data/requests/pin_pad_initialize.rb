# coding: utf-8

require_relative 'abstract_request'

module ClientForPoslynx
  module Data
    module Requests

      class PinPadInitialize < AbstractRequest

        defining_element_value attribute: :command, element: 'Command', value: 'PPINIT'
        attr_element_mapping attribute: :idle_prompt, element: 'IdlePrompt'

      end

    end
  end
end
