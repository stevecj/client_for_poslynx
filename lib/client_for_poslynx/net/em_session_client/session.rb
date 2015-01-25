# coding: utf-8

module ClientForPoslynx
  module Net
    class EM_SessionClient

      class Session
        attr_accessor :_connection_handler
        private       :_connection_handler

        def initialize(connection_listener, connection_initiator)
          @connection_listener  = connection_listener
          @connection_initiator = connection_initiator
          @state = :prepared
        end

        def send_request(request_data, options={})
          if connection_listener.is_connected
            _send_request request_data, options
          else
            # Per EM documentation, we can't expect to keep using a
            # connection handler instance after disconnect, so make
            # the request after re-connecting with a new connection
            # handler instance.
            connection_listener.on_connection_completed = ->(session){
              connect_done!
              _send_request request_data, options
            }
            connection_listener.on_unbind = ->(session){
              connect_done!
              options[:failed].call if options[:failed]
            }
            connect
          end
        end

        def closed?
          state == :closed
        end

        private

        def connect_done!
          connection_listener.on_connection_completed = nil
          connection_listener.on_unbind = nil
        end

        attr_reader :connection_listener, :connection_initiator
        attr_accessor :state

        def _send_request(request_data, options)
          self.state = :connected
          connection_listener.on_receive_response = ->(session, response){
            send_request_done!
            options[:responded].call(response) if options[:responded]
          }
          connection_listener.on_unbind = ->(*){
            send_request_done!
            self.state = :closed
            options[:failed].call if options[:failed]
          }
          _connection_handler.send_request request_data
        end

        def send_request_done!
          connection_listener.on_receive_response = nil
          connection_listener.on_unbind = nil
        end

        def connect
          connection_initiator.call
        end
      end

    end
  end
end
