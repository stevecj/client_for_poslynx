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
        show_waiting_for_connection
        accept_tcp_connection
        show_connection_active

        # Not bothering with graceful shutdown or handlinng of disconnect
        # and reconnect. Just loop until killed by signal or exception.
        while true
          request = request_getter.get_data
          response = request.accept_visitor request_handler
          tcp_connection.puts response.xml_serialize
        end
      end

      private

      attr_reader :tcp_connection

      def show_waiting_for_connection
        user_interface.status_line =
          "Fake POS Terminal ・ TCP port #{port_number} ・ Waiting for connection…"
        user_interface.reset "initialized"
      end

      def show_connection_active
        user_interface.status_line =
          "Fake POS Terminal ・ TCP port #{port_number} ・ Connection active"
        user_interface.reset "initialized"
      end

      def accept_tcp_connection
        @tcp_connection = tcp_server.accept
      end

      def request_getter
        @request_getter ||= MessageHandling.stream_data_extractor( tcp_connection )
      end

      def request_handler
        @request_handler ||= RequestHandler.new( user_interface )
      end

      def tcp_server
        @tcp_server ||= TCPServer.new( port_number )
      end

    end

  end
end
