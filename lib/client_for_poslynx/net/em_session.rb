# coding: utf-8

module ClientForPoslynx
  module Net

    class EM_Session
      class Error < StandardError ; end
      class RequestError < Error ; end
      class ConflictingRequestError < Error ; end

      def self.execute(connector)
        new( connector ).execute { |s| yield s }
      end

      attr_reader :connector

      def initialize(connector)
        @connector = connector
      end

      def execute
        @fiber = Fiber.new do
          yield self
          :done
        end
        callback = fiber.resume
        send *callback unless callback == :done
      end

      def request(data)
        if connector.status_of_request == :pending
          pending_request_data = connector.latest_request[0]
          pending_opts = connector.latest_request[1]
          if Data::Requests::PinPadReset === data && Data::Requests::PinPadReset === pending_request_data
            pending_opts[:on_failure].call if pending_opts[:on_failure]
            was_successful, resp_data_or_ex = Fiber.yield( [:_get_response] )
          elsif data.class == pending_request_data.class
            raise ConflictingRequestError, "Attempted a request while another request of the same type is in progress"
          else
            pending_opts[:on_failure].call if pending_opts[:on_failure]
            was_successful, resp_data_or_ex = Fiber.yield( [:_request, data] )
          end
        else
          was_successful, resp_data_or_ex = Fiber.yield( [:_request, data] )
        end
        raise resp_data_or_ex unless was_successful
        resp_data_or_ex
      end

      private

      attr_reader :fiber

      def _request(data)
        connector.connect(
          on_success: ->() {
            connector.send_request data, response_handlers
          },
          on_failure: ->() {
            fiber.resume( [false, RequestError.new] )
          }
        )
      rescue StandardError => e
        fiber.resume( [false, e] )
      end

      def _get_response
        connector.get_response response_handlers
      end

      def response_handlers
        {
          on_response: ->(response_data) {
            fiber.resume( [true, response_data] )
          },
          on_failure: ->() {
            fiber.resume( [false, RequestError.new] )
          }
        }
      end
    end

  end
end
