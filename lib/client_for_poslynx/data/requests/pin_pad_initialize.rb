# coding: utf-8

require_relative '../abstract_data'

module ClientForPoslynx
  module Data
    module Requests

      class PinPadInitialize < AbstractData
        defining_element_value attribute: :command, element: 'Command', value: 'PPINIT'

        attr_element_mapping attribute: :client_mac,  element: 'ClientMAC'
        attr_element_mapping attribute: :idle_prompt, element: 'IdlePrompt'

        def self.root_element_name
          'PLRequest'
        end

        def initialize
          self.client_mac = Data::DEFAULT_CLIENT_MAC
        end

      end

    end
  end
end
