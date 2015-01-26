# coding: utf-8

module ClientForPoslynx
  module Net
    class EM_SessionClient

      class ConnectionListener
        attr_accessor :is_connected
        private       :is_connected=
        attr_accessor :latest_conn_handler

        attr_accessor(
          :on_unbind,
          :on_connection_completed,
          :on_receive_response,
        )

        def receive_response(response)
          use_event_listener :receive_response, response
        end

        def connection_completed(conn_handler)
          self.latest_conn_handler = conn_handler
          self.is_connected = true
          use_event_listener :connection_completed
        end

        def unbind(conn_handler)
          self.is_connected = false
          use_event_listener :unbind
        end

        private

        # Calls back to an event listener (if any) and
        # clears the listener
        def use_event_listener(kind, *args)
          el = self.send( "on_#{kind}" )
          self.send "on_#{kind}=", nil
          el.call latest_conn_handler, *args if el
        end
      end

    end
  end
end
