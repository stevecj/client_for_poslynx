# coding: utf-8

module ClientForPoslynx
  module Net

    class EM_Session
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
        Fiber.yield( [:_request, data] )
      end

      private

      attr_reader :fiber

      def _request(data)
        connector.connect on_completed: ->() {
          connector.send_request data, on_response: ->(response_data) {
            fiber.resume response_data
          }
        }
      end
    end

  end
end
