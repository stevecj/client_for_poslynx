# coding: utf-8

module ClientForPoslynx
  module FakePosTerminal
    class ConsoleUserInterface

      module Paint
        extend self

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
