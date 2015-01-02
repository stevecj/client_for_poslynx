# coding: utf-8

module ClientForPoslynx
  module FakePosTerminal
    class ConsoleUserInterface

      class UserRawTextLineFetcher
        attr_reader :ui, :entry_validator, :result_listener

        def initialize(ui, entry_validator, result_listener)
          @ui               = ui
          @entry_validator  = entry_validator
          @result_listener  = result_listener
        end

        def call
          start_wait_loop
        end

        def start_wait_loop
          ui.user_text_line_handler = method( :receive_line )
        end

        def receive_line(line)
          entry = line.strip

          if valid_entry?( entry )
            handle_valid_entry entry
          else
            start_wait_loop
          end
        end

        def handle_valid_entry(entry)
          ui.user_text_line_handler = nil
          result_listener.call entry
        end

        def valid_entry?(entry)
          entry_validator.call( entry )
        end

      end

    end
  end
end
