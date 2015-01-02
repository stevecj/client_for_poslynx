# coding: utf-8

require 'delegate'

module ClientForPoslynx
  module FakePosTerminal
    class ConsoleUserInterface

      # This module is included by classes acting as components
      # of the console UI, needing to perform console I/O
      # interactions.
      module IsUI_Component
        extend Forwardable
        include FakePosTerminal::ValueFormatting

        private

        def ui_context
          raise NotImplementedError, "Inheriting-class responsibility"
        end

        def_delegators(
          :ui_context,

          :term_manipulator,
          :user_text_line_handler,
          :user_text_line_handler=,
          :status_line,
          :status_line=,
          :idle_prompt,
          :idle_prompt=,
        )

        def idle!
          term_manipulator.raw_mode!
          self.user_text_line_handler = nil
        end

        def term_manipulator
          ui_context.term_manipulator
        end

        def reset(idle_prompt=nil)
          self.idle_prompt = idle_prompt if idle_prompt
          display_content format_welcome_with_idle_prompt
        end

        def display_content(content, options = {})
          clear_first = options.fetch(:clear){ true }
          clear_screen if clear_first
          write_status_line
          write_top_border

          puts content

          write_bottom_border
        end

        def update_status_line(new_text=nil)
          self.status_line = new_text unless new_text.nil?
          save_cursor_position
          write_status_line
          restore_cursor_position
        end

        def write_status_line
          cursor_to_top_left
          clear_to_end_of_line
          puts " << #{status_line} >>"
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

        def format_multiline_message(text_lines)
          centered_lines = text_lines.map { |text| text.center(68) }
          "\n" << centered_lines * "\n" << "\n\n"
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

        def display_signature_entry_box
          display_content format_signature_entry_box
        end

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

        def prompt_for_button_selection(button_labels)
          puts
          print "Enter the number for your button selection: "
          save_cursor_position
          puts '', ''
          button_labels.each_with_index do |label, idx|
            button_num = idx + 1
            puts ' %d) %s' % [ button_num, label ]
          end
          restore_cursor_position
        end

        def fetch_user_button_number_selection(button_count, selection_listener)
          UserButtonNumberSelectionFetcher.new( ui_context, button_count, selection_listener ).start_process
        end

        def write_top_border
          puts <<-EOS
 __________________________________________________________________
|                                                                  |
          EOS
        end

        def write_bottom_border
          puts <<-EOS
|__________________________________________________________________|
          EOS
        end

        def clear_screen
          print "\x1b[2J"
        end

        def clear_to_end_of_screen
          print "\x1b[J"
        end

        def save_cursor_position
          print "\x1b[s"
        end

        def restore_cursor_position
          print "\x1b[u"
        end

        def to_start_of_line
          print "\x1b[0G"
        end

        def cursor_to_top_left
          print "\x1b[1;1H"
        end

        def clear_to_end_of_line
          print "\x1b[K"
        end
      end

    end
  end
end
