# coding: utf-8

require_relative 'requests/credit_card_sale'
require_relative 'requests/pin_pad_initialize'
require_relative 'requests/can_visit'

module ClientForPoslynx
  module Data

    module Requests

      ROOT_ELEMENT_NAME = 'PLRequest'
      DEFAULT_CLIENT_MAC = 'F' * 12

    end

  end
end
