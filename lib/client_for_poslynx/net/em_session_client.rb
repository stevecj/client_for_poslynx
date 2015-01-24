# coding: utf-8

require_relative 'structured_client/em_connection'

module ClientForPoslynx
  module Net

    class EM_SessionClient

      class EM_ConnectionBase < EM::Connection
        include EM::Protocols::POSLynx
      end

      module HandlesConnection
        attr_reader :listener

        def initialize(listener)
          @listener = listener
        end

        def post_init
          listener.post_init self
        end

        def receive_response(response)
          listener.receive_response response
        end

        def unbind
          listener.unbind self
        end
      end

      class ConnectionListener
        attr_accessor :is_connected
        private       :is_connected=

        attr_accessor(
          :on_unbind,
          :on_post_init,
          :on_receive_response,
        )

        def initialize(session_pool)
          @session_pool = session_pool
        end

        def receive_response(response)
          use_event_listener :receive_response, response
        end

        def post_init(conn_handler)
          self.latest_conn_handler = conn_handler
          self.is_connected = true
          use_event_listener :post_init
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
            el.call session, *args
          end
        end

      end

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
            connection_listener.on_post_init = ->(session){
              _send_request request_data, options
            }
            connect
          end
        end

        def closed?
          state == :closed
        end

        private

        attr_reader :connection_listener, :connection_initiator
        attr_accessor :state

        def _send_request(request_data, options)
          self.state = :connected
          connection_listener.on_receive_response = ->(*args){
            send_request_done!
            options[:responded].call *args if options[:responded]
          }
          connection_listener.on_unbind = ->(*args){
            send_request_done!
            self.state = :closed
            options[:failed].call *args if options[:failed]
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

      def initialize(host, port, opts)
        @host = host
        @port = port
        @em_system = opts.fetch(:em_system){ ::EM }
        connection_base_class = opts.fetch(:connection_base_class) { EM_ConnectionBase }
        @connection_handler_class = Class.new( connection_base_class ) do
          include EM_SessionClient::HandlesConnection
        end
        @session_pool = []
        @connection_listener = EM_SessionClient::ConnectionListener.new( session_pool )
      end

      def start_session(opts = {})
        session = EM_SessionClient::Session.new( connection_listener, method(:connect) )
        session_pool << session
        if connection_listener.is_connected
          opts[:connected].call( session ) if opts[:connected]
        else
          connection_listener.on_unbind    = opts[:failed_connection]
          connection_listener.on_post_init = opts[:connected]
          connect
        end
      end

      private

      attr_reader(
        :host,
        :port,
        :em_system,
        :connection_handler_class,
        :session_pool,
        :connection_listener,
      )

      def connect
        em_system.connect(
          host, port, connection_handler_class,
          connection_listener
        )
      end

    end

  end
end
