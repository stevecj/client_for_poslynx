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
        responder = Responder.new( user_interface )
        user_interface.status_line =
          "Fake POS Terminal ・ TCP port #{port_number} ・ Waiting for connection…"
        user_interface.reset "initialized"
        conn = server.accept
        user_interface.status_line =
          "Fake POS Terminal ・ TCP port #{port_number} ・ Connection active"
        user_interface.reset "initialized"
        # Not bothering with graceful shutdown or handlinng of disconnect
        # and reconnect. Just loop until killed by signal or exception.
        while true
          request = get_request(conn)
          response = request.accept_visitor responder
          conn.puts response.xml_serialize
        end
      end

      private

      def get_request(conn)
        xml = ''
        until xml =~ %r!</PLRequest>[\s\r\n]*\z!m
          xml << conn.gets
        end
        Data::AbstractData.xml_parse(xml)
      end

    end

  end
end
