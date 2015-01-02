# coding: utf-8

require 'bigdecimal'

module ClientForPoslynx
  module FakePosTerminal

    module NetHandler
      include EM::Protocols::LineProtocol

      attr_reader :user_interface

      def initialize(user_interface)
        @user_interface = user_interface
      end

      def post_init
        user_interface.indicate_connected
      end

      def receive_request(request)
        response_class = request.class.response_class
        user_interface.handle_request(
          request,
          response_class.new,
          method( :send_response )
        )
      end

      def send_response(response)
        serial_data = response.xml_serialize
        send_data serial_data
      end

      def receive_line(line)
        _request_buffer.add_line line do |complete_message|
          request = ClientForPoslynx::Data::AbstractData.xml_parse( complete_message )
          receive_request request
        end
      end

      def _request_buffer
        @_request_buffer ||= ClientForPoslynx::MessageHandling::XmlLinesBuffer.new
      end

    end

  end
end
