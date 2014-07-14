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
        tcp_connection.puts request.xml_serialize
        response_getter.get_data
      end

      private

      def response_getter
        @response_getter ||= MessageHandling.stream_data_reader( tcp_connection )
      end

      def tcp_connection
        @tcp_connection ||= TCPSocket.new(config.host, config.port)
      end

    end

    class Config
      attr_accessor :host, :port
    end

  end
end
