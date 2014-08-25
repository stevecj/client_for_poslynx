# coding: utf-8

module ClientForPoslynx
  module FakePosTerminal

    class RequestDispatcher
      include Data::Requests::CanVisit

      REQUEST_NAMES = %w[
        PinPadInitialize
        PinPadDisplayMessage
        CreditCardSale
      ]

      attr_reader :user_interface

      def initialize(user_interface)
        @user_interface = user_interface
      end

      REQUEST_NAMES.each do |request_name|
        eval <<-EOS, nil, __FILE__, __LINE__ + 1

          def visit_#{request_name}(request_data)
            FakePosTerminal::RequestHandlers::#{request_name}.call request_data, user_interface
          end

        EOS
      end

    end

  end
end
