# coding: utf-8

require 'termios'

module ClientForPoslynx
  module FakePosTerminal
    class ConsoleUserInterface

      class TermManipulator
        attr_accessor :original_term_attributes
        private       :original_term_attributes=

        def initialize
          self.original_term_attributes = Termios.tcgetattr($stdin)
        end

        def raw_mode!
          ta = original_term_attributes.dup
          ta.lflag &= ~Termios::ECHO
          ta.lflag &= ~Termios::ICANON
          Termios::tcsetattr $stdin, Termios::TCSANOW, ta
        end

        def interactive_mode!
          ta = original_term_attributes.dup
          ta.lflag |= Termios::ECHO
          ta.lflag |= Termios::ICANON
          Termios::tcsetattr $stdin, Termios::TCSANOW, ta
        end

      end

    end
  end
end
