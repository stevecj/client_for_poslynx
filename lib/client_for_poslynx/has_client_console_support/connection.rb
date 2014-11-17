require 'socket'
require 'openssl'
require 'forwardable'

module ClientForPoslynx
  module HasClientConsoleSupport

    class Connection
      def self.connect(config)
        new(config).connect
      end

      attr_accessor :io
      private       :io=

      def initialize(config)
        self.config = config
      end

      def connect
        self.tcp_connection = TCPSocket.new( config.host, config.port )
        self.io = config.use_ssl ?
          connect_ssl_socket :
          tcp_connection
        self
      rescue StandardError
        close
        raise
      end

      def close
        tcp_connection.close unless tcp_connection.closed?
        self.io = self.tcp_connection = nil
      end

      def puts(*args)
        io.puts *args
      end

      def ===(other)
        self == other || self.io == other
      end

      private

      def connect_ssl_socket
        OpenSSL::SSL::SSLSocket.new( tcp_connection ).tap { |ssl_conn|
          ssl_conn.connect
        }
      end

      attr_accessor :config, :tcp_connection
    end

  end
end
