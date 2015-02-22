# coding: utf-8

module ClientForPoslynx
  module Net
    class EM_Connector

      module HandlesConnection
        include EM::Protocols::POSLynx

        attr_reader :event_listener

        def initialize(event_listener)
          @event_listener = event_listener
          @use_ssl = use_ssl
        end

        def connection_completed
          if use_ssl
            start_tls verify_peer: false
          else
            event_listener.connection_completed self
          end
        end

        def ssl_handshake_completed
          event_listener.connection_completed self
        end

        def unbind
          event_listener.unbind self
        end

        def receive_response(response_data)
          event_listener.receive_response response_data
        end
      end

    end
  end
end
