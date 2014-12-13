# coding: utf-8

require_relative 'structured_client/em_connection'

module ClientForPoslynx
  module Net

    # A network client API suitable for use in a Structured (as
    # oppoesed to Event-Driven) context such as an IRB console.
    class StructuredClient
      attr_reader :directive_queue, :activity_queue

      def initialize(host, port)
        @directive_queue = Queue.new
        @activity_queue  = Queue.new
        @em_thread = Thread.new do
          EM.run do
            EM.connect host, port, EM_Connection, directive_queue, activity_queue
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

      def got_response
        process_new_activity
        received_responses.shift
      end

      private

      def process_new_activity
        until activity_queue.empty?
          process_activity_entry *activity_queue.shift
        end
      end

      def process_activity_entry(kind, data=nil)
        case kind
        when :received_response
          received_responses << data
        end
      end

      def received_responses
        @received_responses ||= []
      end

    end

  end
end
