# coding: utf-8

#require_relative 'format'
require_relative 'console_user_interface/is_ui_component'
require_relative 'console_user_interface/ui_context'
require_relative 'console_user_interface/content_formatter'
require_relative 'console_user_interface/term_manipulator'
require_relative 'console_user_interface/user_text_line_fetcher'
require_relative 'console_user_interface/user_raw_text_line_fetcher'
require_relative 'console_user_interface/user_button_number_selection_fetcher'
require_relative 'console_user_interface/request_handler'
require_relative 'console_user_interface/request_processors'

module ClientForPoslynx
  module FakePosTerminal

    class ConsoleUserInterface
      include IsUI_Component

      attr_reader :context, :ui_context

      def initialize(context)
        @ui_context = UI_Context.new
        @context    = context
      end

      def engage
        term_manipulator.raw_mode!
      end

      def disengage
        term_manipulator.interactive_mode!
      end

      def handle_request(request, response, result_listener)
        idle!
        handler = RequestHandler.new( ui_context, request, response, result_listener )
        handler.call
      end

      def waiting_for_user_text?
        !! user_text_line_handler
      end

      def receive_user_text_line(line)
        user_text_line_handler.call( line ) if user_text_line_handler
      end

      def show_starting_up
        self.status_line =
          "Fake POS Terminal ・ TCP port #{context.port_number} ・ Starting up…"
        reset "Closed"
      end

      public :update_status_line

      def client_connected
        update_status_line(
          "Fake POS Terminal ・ TCP port #{context.port_number} ・ Client is connected"
        )
      end

      def client_disconnected
        idle!
        update_status_line(
          "Fake POS Terminal ・ TCP port #{context.port_number} ・ Waiting for connection…"
        )
      end

    end

  end
end
