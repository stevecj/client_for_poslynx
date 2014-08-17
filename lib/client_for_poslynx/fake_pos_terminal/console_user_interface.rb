# coding: utf-8

module ClientForPoslynx
  module FakePosTerminal

    class ConsoleUserInterface
      attr_accessor :status_line

      def update_status_line(new_text=nil)
        self.status_line = new_text unless new_text.nil?
        save_cursor_position
        write_status_line
        restore_cursor_position
      end

      def reset(idle_prompt)
        display_content format_welcome_with_idle_prompt( idle_prompt )
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

      def get_button_selection(button_labels)
        puts
        print "Enter the number for your button selection: "
        save_cursor_position
        puts '', ''
        button_labels.each_with_index do |label, idx|
          button_num = idx + 1
          puts ' %d) %s' % [ button_num, label ]
        end
        while true
          restore_cursor_position
          clear_to_end_of_line
          entry = gets.strip
          next unless entry =~ /\A\d+\Z/
          entry = entry.to_i
          next if entry < 1 or entry > button_labels.length
          break
        end
        button_idx = entry - 1
        button_labels[button_idx]
      end

      private

      def display_content(content)
        clear_screen
        write_status_line
        write_top_border

        puts content

        write_bottom_border
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

      def format_welcome_with_idle_prompt(idle_prompt)
'
                        ___       _    _            ___
             |   |   | |    |    / \  / \  |     | |
             |   |   | |    |   |    |   | |\   /| |    
             |   |   | |--  |   |    |   | | \ / | |--
             |  / \  | |    |   |    |   | |  |  | |    
              \/   \/  |___ |___ \_/  \_/  |  |  | |___

' + "  (#{idle_prompt})\n"
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

      def clear_screen
        print "\x1b[2J"
      end

      def save_cursor_position
        print "\x1b[s"
      end

      def restore_cursor_position
        print "\x1b[u"
      end

      def write_status_line
        cursor_to_top_left
        clear_to_end_of_line
        puts " << #{status_line} >>"
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
