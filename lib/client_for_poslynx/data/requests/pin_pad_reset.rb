# coding: utf-8

require_relative 'abstract_request'

module ClientForPoslynx
  module Data
    module Requests

      class PinPadReset < AbstractRequest

        defining_property_value attribute: :command, element: 'Command', value: 'PPRESET'

      end

    end
  end
end
