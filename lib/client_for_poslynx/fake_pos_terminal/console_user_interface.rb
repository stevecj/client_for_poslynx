# coding: utf-8

module ClientForPoslynx
  module FakePosTerminal

    class ConsoleUserInterface
      attr_accessor :status_line

      def reset(idle_prompt)
        display_welcome idle_prompt
      end

      def update_status_line(new_text=nil)
        self.status_line = new_text unless new_text.nil?
        print "\x1b[s"
        write_status_line
        print "\x1b[u"
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
        puts "\x1b[1;1H\x1bK << #{status_line} >>"
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
