# coding: utf-8

module ClientForPoslynx
  module FakePosTerminal

    class ConsoleUserInterface
      attr_accessor :status_line

      def reset(idle_prompt)
        display_welcome idle_prompt
      end

      private

      def display_welcome(idle_prompt)
        display_content '
                        ___       _    _            ___
             |   |   | |    |    / \  / \  |     | |
             |   |   | |    |   |    |   | |\   /| |    
             |   |   | |--  |   |    |   | | \ / | |--
             |  / \  | |    |   |    |   | |  |  | |    
              \/   \/  |___ |___ \_/  \_/  |  |  | |___

' + "  (#{idle_prompt})\n"
      end

      def display_content(content)
        clear_screen
        write_status_line
        write_top_border

        puts content

        write_bottom_border
      end

      def clear_screen
        puts "\x1b[2J\x1b[1;1H"
      end

      def write_status_line
        puts " << #{status_line} >>"
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

    end

  end
end
