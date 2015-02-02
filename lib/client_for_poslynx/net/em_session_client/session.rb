# coding: utf-8

module ClientForPoslynx
  module Net
    class EM_SessionClient

      class Session
        # To allow exmining the state of the connection most
        # recently used by the session.
        attr_accessor :connection_handler
        private       :connection_handler=

        def initialize(session_pool, connection_accessor)
          @session_pool = session_pool
          @connection_accessor = connection_accessor
          @state = :prepared
        end

        def to_em_session
          self
        end

        def send_request(request_data, opts={})
          set_pending_request request_data, opts
          other_sessions.each do |os| ; os.finish ; end
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

        def finish
          self.state = :finished
        end

        def finished?
          state == :finished
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

        def idle?
          !!pending_request
        end

        private

        attr_reader :session_pool, :connection_accessor, :pending_request
        attr_accessor :state

        def result_listener_for(listener)
          ->(conn_handler, *args) {
            self.connection_handler = conn_handler
            listener.call *args if listener
          }
        end

        def other_idle_sessions
          other_sessions.select { |os| os.idle? }
        end

        def other_sessions
          session_pool.reject { |ps| ps == self }
        end

        def set_pending_request(request_data, opts)
          @pending_request = {request_data: request_data}.merge( opts )
        end

        def clear_pending_request
          @pending_request = nil
        end
      end

    end
  end
end
