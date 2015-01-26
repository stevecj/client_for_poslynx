# coding: utf-8

module ClientForPoslynx
  module Net
    class EM_SessionClient

      class Session
        attr_accessor :_connection_handler
        private       :_connection_handler

        def initialize(connection_listener, connection_accessor)
          @connection_listener  = connection_listener
          @connection_accessor  = connection_accessor
          @state = :prepared
        end

        def to_em_session
          self
        end

        def send_request(request_data, options={})
          connect(
            connected: ->() {
              _send_request request_data, options
            },
            failed_connection: ->(*) {
              options[:failed].call if options[:failed]
            }
          )
        end

        def closed?
          state == :closed
        end

        def connect(opts={})
          connection_accessor.call(opts)
        end

        private

        attr_reader :connection_listener, :connection_accessor
        attr_accessor :state

        def connect_done!
          connection_listener.on_connection_completed = nil
          connection_listener.on_unbind = nil
        end

        def _send_request(request_data, options)
          self.state = :connected
          connection_listener.on_receive_response = ->(response){
            send_request_done!
            options[:responded].call( response ) if options[:responded]
          }
          connection_listener.on_unbind = ->(){
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
      end

    end
  end
end
