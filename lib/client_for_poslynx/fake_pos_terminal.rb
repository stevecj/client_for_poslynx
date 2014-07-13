# coding: utf-8

require 'client_for_poslynx'
require_relative 'fake_pos_terminal/console_user_interface'
require_relative 'fake_pos_terminal/server'
require_relative 'fake_pos_terminal/request_handler'

module ClientForPoslynx

  # Implements a fake POSLynx server with attached PIN pad.
  # Accepts TCP connections for interaction with a client,
  # and presents a user interface in the terminal that
  # behaves similarly to a POSLynx attached PIN pad.
  module FakePosTerminal

    def self.start(port_number)
      user_interface = ConsoleUserInterface.new
      server = Server.new(port_number, user_interface)
      server.start
    end

  end

end
