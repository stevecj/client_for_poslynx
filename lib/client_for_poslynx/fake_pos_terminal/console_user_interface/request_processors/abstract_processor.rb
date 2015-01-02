# coding: utf-8

module ClientForPoslynx
  module FakePosTerminal
    class ConsoleUserInterface
      module RequestProcessors

        class AbstractProcessor
          attr_reader :ui, :request, :response, :result_listener

          def initialize(ui, request, response, result_listener)
            @ui              = ui
            @request         = request
            @response        = response
            @result_listener = result_listener
          end

          def call
            raise NotImplementedError, "Subclass responsibility"
          end

          def set_result(error_code, result, result_text=nil)
            response.error_code  = error_code
            response.result      = result
            response.result_text = result_text
          end

          def respond
            result_listener.call response
          end

        end

      end
    end
  end
end
