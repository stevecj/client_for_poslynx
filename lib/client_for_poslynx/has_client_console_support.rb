#!/usr/bin/env ruby

require 'client_for_poslynx'
require 'socket'

module ClientForPoslynx

  module HasClientConsoleSupport

    def poslynx_client
      @@poslynx_client ||= Client.new
    end

    class Client

      def config
        @config ||= Config.new
      end

      def send_request(request)
        conn = TCPSocket.new(config.host, config.port)
        conn.puts request.xml_serialize
        response = get_response_from( conn )
        conn.close unless conn.eof?
        response
      end

      private

      def get_response_from( connection )
        reader = MessageHandling.stream_data_reader( connection )
        reader.get_data
      end

    end

    class Config
      attr_accessor :host, :port
    end

  end
end
