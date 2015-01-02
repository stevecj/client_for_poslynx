# coding: utf-8

module ClientForPoslynx
  module FakePosTerminal
    class ConsoleUserInterface

      class UserTextLineFetcher
        include IsUI_Component

        attr_reader :ui_context, :entry_validator, :result_listener

        def initialize(ui_context, entry_validator, result_listener)
          @ui_context       = ui_context
          @entry_validator  = entry_validator
          @result_listener = result_listener
        end

        def call
          save_cursor_position
          start_wait_loop
        end

        def start_wait_loop
          restore_cursor_position
          clear_to_end_of_line
          term_manipulator.interactive_mode!
          self.user_text_line_handler = method( :receive_line )
        end

        def receive_line(line)
          term_manipulator.raw_mode!
          entry = line.strip

          if valid_entry?( entry )
            handle_valid_entry entry
          else
            start_wait_loop
          end
        end

        def handle_valid_entry(entry)
          self.user_text_line_handler = nil
          restore_cursor_position
          result_listener.call entry
        end

        def valid_entry?(entry)
          entry_validator.call( entry )
        end

      end

    end
  end
end
