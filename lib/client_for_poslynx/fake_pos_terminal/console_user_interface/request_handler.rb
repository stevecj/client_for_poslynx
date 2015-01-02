# coding: utf-8

module ClientForPoslynx
  module FakePosTerminal
    class ConsoleUserInterface

      class RequestHandler
        include ClientForPoslynx::Data::Requests::CanVisit

        attr_reader :ui, :request, :response, :result_listener

        def initialize(ui, request, response, result_listener)
          @ui              = ui
          @request         = request
          @response        = response
          @result_listener = result_listener
        end

        def call
          request.accept_visitor self
        end

        def visit_CreditCardSale(visitee)
          process_using RequestProcessors::CreditCardSaleProcessor
        end

        def visit_DebitCardSale(visitee)
          process_using RequestProcessors::DebitCardSaleProcessor
        end

        def visit_PinPadInitialize(visitee)
          process_using RequestProcessors::PinPadInitializeProcessor
        end

        def visit_PinPadReset(visitee)
          process_using RequestProcessors::PinPadResetProcessor
        end

        def visit_PinPadDisplayMessage(visitee)
          process_using RequestProcessors::PinPadDisplayMessageProcessor
        end

        def visit_PinPadDisplaySpecifiedForm(visitee)
          process_using RequestProcessors::PinPadDisplaySpecifiedFormProcessor
        end

        # Processing for this request type has not been implemented yet.
  #      def visit_PinPadGetSignature(visitee) ; end

        # Fall-back for unhandled request types.
        def visit_general(*)
          process_using RequestProcessors::UnsupportedProcessor
        end

        private

        def process_using(klass)
          processor = klass.new( ui, request, response, result_listener )
          processor.call
        end

      end

    end
  end
end
