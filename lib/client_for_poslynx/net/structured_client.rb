# coding: utf-8

require 'eventmachine'

module ClientForPoslynx
  module Net

    # A network client API suitable for use in a Structured (as
    # oppoesed to Event-Driven) context such as an IRB console.
    class StructuredClient
      attr_reader :directive_queue

      def initialize(host, port)
        @directive_queue = Queue.new
        @em_thread = Thread.new do
          EM.run do
            EM.connect host, port, EM_Connection, directive_queue
            EM.error_handler do |e|
              raise e
            end
          end
        end
      end

      def end_session
        directive_queue << :end_session
        @em_thread.join
      end

      def send_request(request_data)
        directive_queue << [ :send_request, request_data ]
      end

      class EM_Connection < EM::Connection
        attr_reader :directive_queue

        def initialize(directive_queue)
          @directive_queue = directive_queue
        end

        def connection_completed
          handle_next_directive
        end

        def unbind
          EM.stop_event_loop
        end

        private

        def handle_next_directive
          EM.defer(
            ->{ directive_queue.shift },
            ->(directive){
              process_directive directive
            }
          )
        end

        def process_directive(directive)
          kind, *args = Array( directive )
          case kind
            when :end_session then end_session
            when :send_request then send_request *args
          end
        end

        def end_session
          after_writing = true
          close_connection after_writing
        end

        def send_request(request)
          serial_data = request.xml_serialize
          send_data serial_data
          handle_next_directive
        end

      end
    end

  end
end
