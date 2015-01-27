# coding: utf-8

module ClientForPoslynx
  module Net
    class EM_SessionClient

      # This module is mixed into an EventManager connection handler
      # class with the POSLynx client protocol included (or surrogate
      # thereof) and forwards responses we care about to the connection
      # listener.
      module HandlesConnection
        attr_reader :listener, :debug_logger

        def initialize(listener, opts={})
          @listener = listener
          @debug_logger = opts.fetch( :debug_logger )
          debug_logger.call(
            "Initialized connection handler (object_id: #{object_id})"
          )
        end

        def connection_completed
          debug_logger.call(
            "Connection handler (object_id: #{object_id}) received connection_completed"
          )
          listener.connection_completed self
        end

        def receive_response(response)
          debug_logger.call(
            "Connection handler (object_id: #{object_id}) received receive_response with response type #{response.class.name}"
          )
          listener.receive_response response
        end

        def unbind
          debug_logger.call(
            "Connection handler (object_id: #{object_id}) received unbind"
          )
          listener.unbind
        end
      end

    end
  end
end
