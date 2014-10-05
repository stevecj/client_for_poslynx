# coding: utf-8

require_relative 'abstract_request'

module ClientForPoslynx
  module Data
    module Requests

      class PinPadGetSignature < AbstractRequest

        defining_property_value attribute: :command, element: 'Command', value: 'PPGETSIGNATURE'

      end

    end
  end
end
