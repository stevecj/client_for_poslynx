# coding: utf-8

module ClientForPoslynx
  module FakePosTerminal
    module RequestHandlers

      class PinPadInitialize < RequestHandlers::AbstractHandler

        def initialize(request, user_interface)
          @request        = request
          @user_interface = user_interface
        end

        def call
          user_interface.reset request.idle_prompt
          @response = Data::Responses::PinPadInitialize.new
          set_result '0000', 'SUCCESS', 'PinPad Initialized'
        end

      end

    end
  end
end
