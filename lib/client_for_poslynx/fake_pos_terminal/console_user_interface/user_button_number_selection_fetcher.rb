# coding: utf-8

module ClientForPoslynx
  module FakePosTerminal
    class ConsoleUserInterface

      class UserButtonNumberSelectionFetcher
        attr_reader :ui, :button_count, :selection_listener, :user_text_line_fetcher

        def initialize(ui, button_count, selection_listener)
          @ui                 = ui
          @button_count       = button_count
          @selection_listener = selection_listener

          @user_text_line_fetcher = UserTextLineFetcher.new(
            ui,
            method(:valid_selection?),
            method(:receive_entry)
          )
        end

        def start_process
          user_text_line_fetcher.call
        end

        def valid_selection?(entry)
          return false unless entry =~ /\A\d+\Z/
          button_num = entry.to_i
          button_num >= 1 and button_num <= button_count
        end

        def receive_entry(entry)
          button_num = entry.to_i
          show_selection button_num
          selection_listener.call button_num
        end

        def show_selection(button_num)
          Paint.to_start_of_line
          Paint.clear_to_end_of_screen
          puts " Selected button #{button_num}"
        end

      end

    end
  end
end
