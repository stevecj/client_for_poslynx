# coding: utf-8

module ClientForPoslynx
  module Net
    class EM_SessionClient
      class ConnectionAccessor

        class ConnectionListener

          Callbacks ||= Struct.new(
            :unbind,
            :connection_completed,
            :receive_response,
          )

          attr_accessor :is_connected
          private       :is_connected=
          attr_accessor :latest_conn_handler


          def set_callbacks
            self.callbacks = Callbacks.new.tap{ |cbs|
              yield cbs
            }
          end

          def clear_callbacks
            self.callbacks = nil
          end

          def connection_completed(conn_handler)
            self.latest_conn_handler = conn_handler
            self.is_connected = true
            make_callback :connection_completed
          end

          def unbind
            self.is_connected = false
            make_callback :unbind
          end

          def receive_response(response)
            make_callback :receive_response, response
          end

          private

          attr_writer :callbacks

          def callbacks
            @callbacks ||= Callbacks.new
          end

          # Calls back to an event listener (if any) and
          # clears the listener
          def make_callback(kind, *args)
            callback = callbacks.send( kind )
            clear_callbacks
            callback.call latest_conn_handler, *args if callback
          end
        end

      end
    end
  end
end
