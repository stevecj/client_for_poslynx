# coding: utf-8

require 'eventmachine'

module ClientForPoslynx
  module Net
    class StructuredClient

      class EM_Connection < EM::Connection
        include EM::Protocols::POSLynx

        attr_reader :directive_queue, :activity_queue

        def initialize(directive_queue, activity_queue)
          @directive_queue = directive_queue
          @activity_queue  = activity_queue
        end

        def connection_completed
          handle_next_directive
        end

        def unbind
          EM.stop_event_loop
        end

        def receive_response(response)
          activity_queue << [ :received_response, response ]
        end

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
          when :end_session
            end_session
          when :send_request
            begin
              send_request *args
            ensure
              handle_next_directive
            end
          end
        end

        def end_session
          after_writing = true
          close_connection after_writing
        end

      end

    end
  end
end
