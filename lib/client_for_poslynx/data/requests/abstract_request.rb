# coding: utf-8

require_relative '../abstract_data'

module ClientForPoslynx
  module Data
    module Requests

      class AbstractRequest < AbstractData

        def self.new
          instance = blank_new
          instance.client_mac = DEFAULT_CLIENT_MAC
          instance
        end

        def self.response_class
          Data::Responses.const_get( short_name )
        end

        def self.root_element_name
          ROOT_ELEMENT_NAME
        end

        attr_element_mapping attribute: :client_mac,  element: 'ClientMAC'

        def accept_visitor(visitor)
          simple_class_name = "#{self.class}".split('::').last
          visitor.public_send "visit_#{simple_class_name}", self
        end

        # True is the given object is of the right type to be a
        # response to a request made using this request data.
        def potential_response?(candidate)
          self.class.response_class === candidate
        end

      end

    end
  end
end
