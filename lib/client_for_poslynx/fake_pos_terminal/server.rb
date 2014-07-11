# coding: utf-8

require 'client_for_poslynx'
require 'socket'

module ClientForPoslynx
  module FakePosTerminal

    class Server
      attr_reader :port_number, :user_interface

      def initialize(port_number, user_interface)
        @port_number    = port_number
        @user_interface = user_interface
      end

      def start
        server = TCPServer.new(port_number)
        user_interface.status_line = "Fake POS Terminal ・ TCP port #{port_number} ・ Waiting for connection…"
        user_interface.reset
        conn = server.accept
        while true
          conn.gets
          user_interface.reset
        end
        conn.close
      end

    end

  end
end
