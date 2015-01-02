# coding: utf-8

require 'bigdecimal'

module ClientForPoslynx
  module FakePosTerminal

    module KeyboardHandler
      #TODO: Get wait for button selection to set strategy to wait for message from me.

      include EM::Protocols::LineProtocol

      attr_accessor :user_interface

      def initialize(user_interface)
        @user_interface = user_interface
      end

      def receive_data(data)
        if user_interface.waiting_for_user_text?
          # Perform normal character input processing.
          super
        else
          # Discard input.
        end
      end

      def receive_line(line)
        user_interface.receive_user_text_line line
      end

    end

  end
end
