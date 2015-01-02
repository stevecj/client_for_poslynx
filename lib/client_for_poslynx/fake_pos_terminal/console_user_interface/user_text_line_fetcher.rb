# coding: utf-8

module ClientForPoslynx
  module FakePosTerminal
    class ConsoleUserInterface

      class UserTextLineFetcher
        attr_reader :ui, :entry_validator, :result_listener

        def initialize(ui, entry_validator, result_listener)
          @ui               = ui
          @entry_validator  = entry_validator
          @result_listener = result_listener
        end

        def call
          Paint.save_cursor_position
          start_wait_loop
        end

        def start_wait_loop
          Paint.restore_cursor_position
          Paint.clear_to_end_of_line
          ui.term_manipulator.interactive_mode!
          ui.user_text_line_handler = method( :receive_line )
        end

        def receive_line(line)
          ui.term_manipulator.raw_mode!
          entry = line.strip

          if valid_entry?( entry )
            handle_valid_entry entry
          else
            start_wait_loop
          end
        end

        def handle_valid_entry(entry)
          ui.user_text_line_handler = nil
          Paint.restore_cursor_position
          result_listener.call entry
        end

        def valid_entry?(entry)
          entry_validator.call( entry )
        end

      end

    end
  end
end
