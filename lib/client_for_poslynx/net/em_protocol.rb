# coding: utf-8

require 'eventmachine'

module EventMachine
  module Protocols

    # Sends requests to and receives responses from a Precidia
    # POSLynx system over TCP/IP.
    module POSLynx
      include EM::Protocols::LineProtocol

      # Called by user code to send a request to the POSLynx
      # system.
      # The request object is expected to behave like an
      # instance of a descendant class of
      # ClientForPoslynx::Data::Requests::AbstractRequest.
      def send_request(request)
        serial_data = request.xml_serialize
        send_data serial_data
      end

      # Invoked with responses received from the POSLynx system.
      # Each response will be an instance of a descendent class
      # of
      # ClientForPoslynx::Data::Responses::AbstractResponse.
      def receive_response(response)
        # stub
      end

      # @private
      def receive_line(line)
        _response_buffer.add_line line do |complete_message|
          response = ClientForPoslynx::Data::AbstractData.xml_parse( complete_message )
          receive_response response
        end
      end

      # @private
      def _response_buffer
        @_response_buffer ||= MessageLinesBuffer.new
      end

      class MessageLinesBuffer
        def initialize
          reset
        end

        def add_line(line)
          message << line
          if (! root_name) && line =~ /^(?:<\?.+?\?>)?<([A-Za-z_][^\s>]*)[ >]/
            self.root_name = $1
          end
          if root_name && line =~ /<\/#{root_name}\s*>\s*$/
            complete_message = message
            reset
            yield complete_message
          end
        end

        private

        attr_reader   :message
        attr_accessor :root_name

        def reset
          @message   = ''
          @root_name = nil
        end
      end

    end

  end
end
