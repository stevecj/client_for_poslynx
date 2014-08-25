# coding: utf-8

module ClientForPoslynx
  module FakePosTerminal
    module RequestHandlers

      class AbstractHandler
        attr_reader :request, :response, :user_interface

        def self.call(*args)
          instance = new(*args)
          instance.call
          instance.response
        end

        def initialize(request, user_interface)
          @request        = request
          @user_interface = user_interface
        end

        def call
          raise NotImplementedError
        end

        private

        def set_result(error_code, result, result_text=nil)
          response.error_code  = error_code
          response.result      = result
          response.result_text = result_text
        end

      end

    end
  end
end
