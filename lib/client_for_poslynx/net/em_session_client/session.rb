# coding: utf-8

module ClientForPoslynx
  module Net
    class EM_SessionClient

      class Session
        # To allow exmining the state of the connection most
        # recently used by the session.
        attr_accessor :connection_handler
        private       :connection_handler=

        def initialize(connection_accessor)
          @connection_accessor = connection_accessor
          @state = :prepared
        end

        def to_em_session
          self
        end

        def send_request(request_data, opts={})
          connection_accessor.send_request(
            request_data,
            responded: result_listener_for(
              ->(response){
                self.state = :connected
                opts[:responded].call( response ) if opts[:responded]
              }
            ),
            failed: result_listener_for(
              ->(){
                self.state = :closed
                opts[:failed].call if opts[:failed]
              }
            )
          )
        end

        def closed?
          state == :closed
        end

        def connect(opts={})
          connection_accessor.get_connection(
            connected: result_listener_for(
              ->(){
                self.state = :connected
                opts[:connected].call if opts[:connected]
              }
            ),
            failed_connection: result_listener_for(
              ->(){
                self.state = :closed
                opts[:failed_connection].call if opts[:failed_connection]
              }
            )
          )
        end

        private

        attr_reader :connection_accessor
        attr_accessor :state

        def result_listener_for(listener)
          ->(conn_handler, *args) {
            self.connection_handler = conn_handler
            listener.call *args if listener
          }
        end
      end

    end
  end
end
