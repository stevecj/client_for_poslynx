# coding: utf-8

require_relative '../abstract_data'

module ClientForPoslynx
  module Data
    module Requests

      class AbstractRequest < AbstractData
        attr_element_mapping attribute: :client_mac,  element: 'ClientMAC'

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
