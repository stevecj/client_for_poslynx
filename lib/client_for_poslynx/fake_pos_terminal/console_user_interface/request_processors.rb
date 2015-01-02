# coding: utf-8

require_relative 'request_processors/abstract_processor'
require_relative 'request_processors/processes_card_sale'
require_relative 'request_processors/credit_card_sale_processor'
require_relative 'request_processors/debit_card_sale_processor'
require_relative 'request_processors/pin_pad_initialize_processor'
require_relative 'request_processors/pin_pad_reset_processor'
require_relative 'request_processors/pin_pad_display_message_processor'
require_relative 'request_processors/pin_pad_display_specified_form_processor'
require_relative 'request_processors/unsupported_processor'

module ClientForPoslynx
  module FakePosTerminal
    class ConsoleUserInterface

      module RequestProcessors
      end

    end
  end
end
