# coding: utf-8

module ClientForPoslynx
  module Net
    class EM_Connector

      def self.RequestCall(*args)
        if args.length == 1 && self::RequestCall === args.first
          args.first
        elsif args.first.nil?
          RequestCall.new(nil, {})
        else
          RequestCall.new( *args )
        end
      end

      class RequestCall < Struct.new(:request_data, :result_callbacks)
        def initialize(request_data, result_callbacks={})
          result_callbacks = EMC.CallbackMap( result_callbacks )
          super request_data, result_callbacks
          freeze
        end
      end

    end
  end
end
