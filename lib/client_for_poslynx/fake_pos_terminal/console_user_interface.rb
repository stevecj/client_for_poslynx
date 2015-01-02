# coding: utf-8

#require_relative 'format'
require_relative 'console_user_interface/term_manipulator'
require_relative 'console_user_interface/paint'
require_relative 'console_user_interface/user_text_line_fetcher'
require_relative 'console_user_interface/user_raw_text_line_fetcher'
require_relative 'console_user_interface/user_button_number_selection_fetcher'
require_relative 'console_user_interface/request_handler'
require_relative 'console_user_interface/request_processors'

module ClientForPoslynx
  module FakePosTerminal

    class ConsoleUserInterface
      include FakePosTerminal::Format

      attr_reader :context
      attr_accessor :status_line, :idle_prompt

      attr_accessor :term_manipulator
      attr_accessor :original_term_attributes, :user_text_line_handler

      def initialize(context)
        @context = context
        self.term_manipulator = TermManipulator.new
      end

      def engage
        term_manipulator.raw_mode!
      end

      def disengage
        term_manipulator.interactive_mode!
      end

      def handle_request(request, response, result_listener)
        handler = RequestHandler.new( self, request, response, result_listener )
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

      def indicate_waiting_for_connection
        update_status_line(
          "Fake POS Terminal ・ TCP port #{context.port_number} ・ Waiting for connection…"
        )
      end

      def indicate_connected
        update_status_line(
          "Fake POS Terminal ・ TCP port #{context.port_number} ・ Client is connected"
        )
      end

      def update_status_line(new_text=nil)
        self.status_line = new_text unless new_text.nil?
        Paint.save_cursor_position
        write_status_line
        Paint.restore_cursor_position
      end

      def display_content(content, options = {})
        clear_first = options.fetch(:clear){ true }
        Paint.clear_screen if clear_first
        write_status_line
        Paint.write_top_border

        puts content

        Paint.write_bottom_border
      end

      def display_signature_entry_box
        display_content format_signature_entry_box
      end

      def write_status_line
        Paint.cursor_to_top_left
        Paint.clear_to_end_of_line
        puts " << #{status_line} >>"
      end

      def reset(idle_prompt=nil)
        self.idle_prompt = idle_prompt if idle_prompt
        display_content format_welcome_with_idle_prompt
      end

      def fetch_confirmation(result_listener)
        fetch_button_selection(
          %w[ OK Cancel ],
          ->(button_label) {
            result = case button_label
              when 'OK'     then true
              when 'Cancel' then false
              else               nil
            end
            result_listener.call result
          }
        )
      end

      def fetch_button_selection( button_labels, selection_listener )
        prompt_for_button_selection button_labels
        fetch_user_button_number_selection button_labels.length, ->(button_num) do
          selection_label = button_labels[ button_num - 1 ]
          selection_listener.call selection_label
        end
      end

      def show_message(text_lines)
        display_content format_multiline_message( text_lines )
      end

      def show_message_with_buttons(text_lines, button_labels)
        content =
          format_multiline_message( text_lines ) <<
          format_buttons( button_labels )
        display_content content
      end

      def format_buttons(button_labels)
        button_strings = button_labels.map { |label| "[ #{label} ]" }
        tot_button_space = button_strings.map(&:length).inject{ |m, length| m + length }
        tot_marginal_space = 68 - tot_button_space
        padding_size = tot_marginal_space / ( button_strings.length * 2 )
        padding = ' ' * padding_size
        button_strings.map! { |string| padding + string + padding }
        ( button_strings * '' ).center( 68 )
      end

      def show_pin_request(options = {})
        show_as_filled_in = options.fetch(:filled_in){ false }
        input_box = show_as_filled_in ? '[ * * * * ]' : '[ _ _ _ _ ]'
        content = format_multiline_message( [
          'Please enter your PIN...',
          input_box
        ])
        display_content content, options
      end

      def format_multiline_message(text_lines)
        centered_lines = text_lines.map { |text| text.center(68) }
        "\n" << centered_lines * "\n" << "\n\n"
      end

      def show_payment_confirmation(amount)
        content =
          format_payment_confirmation( amount ) <<
          format_buttons(%w[ OK Cancel ])
        display_content content
      end

      def format_payment_confirmation(amount)
        lines = []
        lines << "TOTAL AMOUNT"
        lines << format_usd( amount )
        format_multiline_message(lines)
      end

      def show_card_swipe_request(options = {})
        options = options.dup
        content = format_card_swipe_request( options )
        display_content content
      end

      def format_card_swipe_request(options = {})
        total = options[:total]
        lines = []
        lines << "Please swipe your card"
        lines << "Total: " + format_usd( total ) if total
        lines << "Transaction: " + options[:transaction]
        format_multiline_message( lines )
      end

      def fetch_fake_card_swipe(result_listener)
        puts
        print "Enter last 4 digits of hypothetical swiped card: "
        UserTextLineFetcher.new(
          self,
          /\A\d{4}\Z/.method(:match),
          result_listener
        ).call
        #UserFakeCardSwipeFetcher.new( self, result_listener ).call
      end

      def get_confirmation
        selected_label = get_button_selection(%w[ OK Cancel ])
        selected_label == 'OK'
      end

      def fetch_fake_pin_entry(after)
        puts
        print "Press enter to pretend to enter a PIN: "
        Paint.save_cursor_position
        UserRawTextLineFetcher.new(
          self,
          ->(entry) { true },
          ->(entry) {
            after.call
          }
        ).call
      end

      private

      def format_welcome_with_idle_prompt
'
                        ___       _    _            ___
             |   |   | |    |    / \  / \  |     | |
             |   |   | |    |   |    |   | |\   /| |    
             |   |   | |--  |   |    |   | | \ / | |--
             |  / \  | |    |   |    |   | |  |  | |    
              \/   \/  |___ |___ \_/  \_/  |  |  | |___

' + "  (#{idle_prompt})\n"
      end

      def format_signature_entry_box
'

      Sign here...
     -----------------------------------------------------------
    |                                                           |
    |                                                           |
    |                                                           |
     -----------------------------------------------------------

'
      end

      def prompt_for_button_selection(button_labels)
        puts
        print "Enter the number for your button selection: "
        Paint.save_cursor_position
        puts '', ''
        button_labels.each_with_index do |label, idx|
          button_num = idx + 1
          puts ' %d) %s' % [ button_num, label ]
        end
        Paint.restore_cursor_position
      end

      def fetch_user_button_number_selection(button_count, selection_listener)
        UserButtonNumberSelectionFetcher.new( self, button_count, selection_listener ).start_process
      end

    end

  end
end
