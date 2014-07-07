# coding: utf-8

require_relative 'requests/xml_parser'
require_relative 'requests/credit_card_sale'
require_relative 'requests/pin_pad_initialize'

module ClientForPoslynx
  module Data

    module Requests

      ROOT_NAME = 'PLRequest'
      DEFAULT_CLIENT_MAC = 'F' * 12

    end

  end
end
