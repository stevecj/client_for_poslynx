# coding: utf-8

require 'termios'

module ClientForPoslynx
  module FakePosTerminal
    class ConsoleUserInterface

      class UI_Context
        attr_reader :term_manipulator
        attr_accessor :user_text_line_handler, :status_line, :idle_prompt

        def initialize
          @term_manipulator       = TermManipulator.new
        end

      end

    end
  end
end
