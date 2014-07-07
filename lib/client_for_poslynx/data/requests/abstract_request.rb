# coding: utf-8

require_relative '../abstract_data'

module ClientForPoslynx
  module Data
    module Requests

      class AbstractRequest < AbstractData

        def self.root_element_name
          ROOT_ELEMENT_NAME
        end

        attr_element_mapping attribute: :client_mac,  element: 'ClientMAC'

        def initialize
          self.client_mac = DEFAULT_CLIENT_MAC
        end

      end

    end
  end
end
