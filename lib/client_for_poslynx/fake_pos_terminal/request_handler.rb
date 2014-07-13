# coding: utf-8

require 'client_for_poslynx'

module ClientForPoslynx
  module FakePosTerminal

    class RequestHandler
      include Data::Requests::CanVisit

      attr_reader :user_interface

      def initialize(user_interface)
        @user_interface = user_interface
      end

      def visit_PinPadInitialize(request_data)
        user_interface.reset request_data.idle_prompt
        Data::Responses::PinPadInitialize.new.tap do |resp|
          resp.result      = 'SUCCESS'
          resp.result_text = "PinPad Initialized"
          resp.error_code  = '0000'
        end
      end

    end

  end
end
