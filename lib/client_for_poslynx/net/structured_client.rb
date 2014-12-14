# coding: utf-8

require_relative 'structured_client/em_connection'

module ClientForPoslynx
  module Net

    # A network client API suitable for use in a Structured (as
    # oppoesed to Event-Driven) context such as an IRB console.
    class StructuredClient

      class SessionEndedError  < StandardError ; end
      class SessionEndingError < StandardError ; end

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

      # Close the server connection if it is open and end the
      # session managed by the receiving instance.
      def end_session
        return unless em_thread.status
        directive_queue << :end_session
        self.session_end_initiated = true
        em_thread.join
        nil
      end

      # Sends a request to the POSLynx system and returns
      # immediately.
      # The request object is expected to behave like an
      # instance of a descendant class of
      # ClientForPoslynx::Data::Requests::AbstractRequest.
      def send_request(request_data)
        if session_ended?
          raise SessionEndedError, "The session has been closed and cannot be used to send requests"
        elsif session_ending?
          raise SessionEndingError, "The session is ending and cannot be used to send requests"
        end
        directive_queue << [ :send_request, request_data ]
        nil
      end

      # Returns the next available received response, if any.
      # Returns nil is there are no remaining received responses
      # to get.
      # Each response will be an instance of a descendent class
      # of
      # ClientForPoslynx::Data::Responses::AbstractResponse.
      def get_response
        process_new_activity
        received_responses.shift
      end

      # Returns true if the managed session has ended, either
      # as a result of a call to #end_session or because the
      # connection was closed by the server or otherwise lost.
      def session_ended?
        ! em_thread.status
      end

      private

      attr_reader :em_thread, :directive_queue, :activity_queue
      attr_accessor :session_end_initiated

      def session_ending?
        session_end_initiated && ! session_ended?
      end

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
