# coding: utf-8

require 'eventmachine'

module EventMachine
  module Protocols

    # Sends requests to and receives responses from a Precidia
    # POSLynx system over TCP/IP.
    module POSLynx
      include EM::Protocols::LineProtocol

      # Called by user code te send a request to the POSLynx
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
        self._serial_response << line
        if (! _root_name) && line =~ /^(?:<\?.+?\?>)?<([A-Za-z_][^\s>]*)[ >]/
          self._root_name = $1
        end
        if _root_name && line =~ /<\/#{_root_name}\s*>\s*$/
          sr = _serial_response
          self._reset_response_buffer
          response = ClientForPoslynx::Data::AbstractData.xml_parse( sr )
          receive_response response
        end
      end

      # @private
      attr_writer :_serial_response

      # @private
      def _serial_response
        @_serial_response ||= ''
      end

      # @private
      attr_accessor :_root_name

      # @private
      def _reset_response_buffer
        self._serial_response = ''
        self._root_name = nil
      end

    end

  end
end
