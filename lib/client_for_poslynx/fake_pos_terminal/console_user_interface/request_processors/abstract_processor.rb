# coding: utf-8

module ClientForPoslynx
  module FakePosTerminal
    class ConsoleUserInterface
      module RequestProcessors

        class AbstractProcessor
          include IsUI_Component

          attr_reader :ui_context, :request, :response, :result_listener

          def initialize(ui_context, request, response, result_listener)
            raise 'foo' if ui_context.nil?
            @ui_context      = ui_context
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
            idle!
          end

        end

      end
    end
  end
end
