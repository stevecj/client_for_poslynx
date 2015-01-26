# coding: utf-8

module ClientForPoslynx
  module Net
    class EM_SessionClient

      class ConnectionListener
        attr_accessor :is_connected
        private       :is_connected=

        attr_accessor(
          :on_unbind,
          :on_connection_completed,
          :on_receive_response,
        )

        def initialize(session_pool)
          @session_pool = session_pool
        end

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

        attr_reader :session_pool
        attr_accessor :latest_conn_handler

        # Calls back to an event listener (if any) and
        # clears the listener
        def use_event_listener(kind, *args)
          el = self.send( "on_#{kind}" )
          self.send "on_#{kind}=", nil
          if el
            session = session_pool.last
            session._connection_handler = latest_conn_handler
            el.call *args
          end
        end
      end

    end
  end
end
