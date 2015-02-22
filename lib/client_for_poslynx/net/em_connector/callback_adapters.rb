# coding: utf-8

require_relative 'callback_adapters/base'
require_relative 'callback_adapters/connect'
require_relative 'callback_adapters/send_request'
require_relative 'callback_adapters/close_connection'

module ClientForPoslynx
  module Net
    class EM_Connector

      module CallbackAdapters
      end

    end
  end
end
