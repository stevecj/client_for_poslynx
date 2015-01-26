# coding: utf-8

module ClientForPoslynx
  module Net
    class EM_SessionClient

      class Session
        attr_accessor :_connection_handler
        private       :_connection_handler

        def initialize(connection_accessor)
          @connection_accessor  = connection_accessor
          @state = :prepared
        end

        def to_em_session
          self
        end

        def send_request(request_data, options={})
          connect(
            connected: ->(conn_handler) {
              self._connection_handler = conn_handler
              _send_request request_data, options
            },
            failed_connection: ->(conn_handler) {
              self._connection_handler = conn_handler
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

        attr_reader :connection_accessor
        attr_accessor :state

        def _send_request(request_data, options)
          self.state = :connected
          connection_accessor.on_receive_response = ->(conn_handler, response){
            self._connection_handler = conn_handler
            send_request_done!
            options[:responded].call( response ) if options[:responded]
          }
          connection_accessor.on_unbind = ->(conn_handler){
            self._connection_handler = conn_handler
            send_request_done!
            self.state = :closed
            options[:failed].call if options[:failed]
          }
          _connection_handler.send_request request_data
        end

        def send_request_done!
          connection_accessor.on_receive_response = nil
          connection_accessor.on_unbind = nil
        end
      end

    end
  end
end
