# coding: utf-8

module ClientForPoslynx
  module FakePosTerminal
    module RequestHandlers

      class PinPadInitialize < RequestHandlers::AbstractHandler

        def call
          user_interface.reset request.idle_prompt
          @response = Data::Responses::PinPadInitialize.new
          set_result '0000', 'SUCCESS', 'PinPad Initialized'
        end

      end

    end
  end
end
