# coding: utf-8

require_relative 'responses/credit_card_sale'
require_relative 'responses/debit_card_sale'
require_relative 'responses/pin_pad_initialize'
require_relative 'responses/pin_pad_display_message'
require_relative 'responses/pin_pad_display_specified_form'

module ClientForPoslynx
  module Data

    module Responses

      ROOT_ELEMENT_NAME = 'PLResponse'

    end

  end
end
