# coding: utf-8

require 'client_for_poslynx'
require_relative 'fake_pos_terminal/value_formatting'
require_relative 'fake_pos_terminal/context'
require_relative 'fake_pos_terminal/result_assemblers'
require_relative 'fake_pos_terminal/console_user_interface'
require_relative 'fake_pos_terminal/net_handler'
require_relative 'fake_pos_terminal/keyboard_handler'

module ClientForPoslynx

  # Implements a fake POSLynx server with attached PIN pad.
  # Accepts TCP connections for interaction with a client,
  # and presents a user interface in the terminal that
  # behaves similarly to a POSLynx attached PIN pad.
  module FakePosTerminal

    def self.start(port_number)
      context = self::Context.new
      context.port_number = port_number

      user_interface = self::ConsoleUserInterface.new( context )
      user_interface.engage
      user_interface.show_starting_up

      EM.run do
        EM.start_server(
          "127.0.0.1", port_number, self::NetHandler,
          user_interface
        )

        EM.open_keyboard(
          self::KeyboardHandler,
          user_interface
        )

        EM.error_handler do |e|
          raise e
        end

        user_interface.client_disconnected
      end

    ensure
      user_interface.disengage if user_interface
    end

  end

end
