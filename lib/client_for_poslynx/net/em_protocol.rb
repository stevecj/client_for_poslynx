# coding: utf-8

require 'eventmachine'

module EventMachine
  module Protocols

    # Sends requests to and receives responses from a Precidia
    # POSLynx system over TCP/IP.
    module POSLynx

      # Called by user code te send a request to the POSLynx
      # system.
      # The request object is expected to behave like an
      # instance of a descendant class of
      # ClientForPoslynx::Data::Requests::AbstractRequest.
      def send_request(request)
        serial_data = request.xml_serialize
        send_data serial_data
      end

    end

  end
end
