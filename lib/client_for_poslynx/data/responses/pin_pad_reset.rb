# coding: utf-8

require_relative 'abstract_response'

module ClientForPoslynx
  module Data
    module Responses

      class PinPadReset < AbstractResponse

        defining_property_value attribute: :command, element: 'Command', value: 'PPRESET'

      end

    end
  end
end
