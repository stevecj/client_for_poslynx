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
        show_waiting_for_first_request
        while true
          conn = tcp_server.accept
          show_connection_active

          request = get_request_from( conn )
          response = request.accept_visitor request_handler
          conn.puts response.xml_serialize
          conn.close
          show_waiting_for_next_request
        end
      end

      private

      def show_waiting_for_first_request
        user_interface.status_line =
          "Fake POS Terminal ・ TCP port #{port_number} ・ Waiting for request…"
        user_interface.reset "initialized - waiting for 1st request"
      end

      def show_connection_active
        user_interface.update_status_line \
          "Fake POS Terminal ・ TCP port #{port_number} ・ Connection active"
      end

      def show_waiting_for_next_request
        user_interface.update_status_line \
          "Fake POS Terminal ・ TCP port #{port_number} ・ Waiting for next request…"
      end

      def get_request_from( connection )
        reader = MessageHandling.stream_data_reader( connection )
        reader.get_data
      end

      def tcp_server
        @tcp_server ||= TCPServer.new( port_number )
      end

      def request_handler
        @request_handler ||= RequestHandler.new( user_interface )
      end

    end

  end
end
