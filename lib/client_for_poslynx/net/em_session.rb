# coding: utf-8

module ClientForPoslynx
  module Net

    class EM_Session
      class RequestError < StandardError
      end

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
          [ :done ]
        end
        callback = fiber.resume
        send *callback
      end

      def request(data)
        was_successful, *args = Fiber.yield( [:_request, data] )
        if was_successful
          args.first
        else
          raise RequestError
        end
      end

      private

      attr_reader :fiber

      def _request(data)
        connector.connect(
          on_success: ->() {
            connector.send_request data, on_response: ->(response_data) {
              fiber.resume( [true, response_data] )
            }
          },
          on_failure: ->() {
            fiber.resume( [false] )
          }
        )
      end
    end

  end
end
