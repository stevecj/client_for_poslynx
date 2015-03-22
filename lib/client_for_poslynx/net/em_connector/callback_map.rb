# coding: utf-8

module ClientForPoslynx
  module Net

    class EM_Connector

      def self.CallbackMap(*args)
        if args.length == 1 && EMC::CallbackMap === args.first
          return args.first
        else
          EMC::CallbackMap.new( *args )
        end
      end

      class CallbackMap
        def initialize(callable_map={})
          @callable_map = callable_map
        end

        def ==(other)
          callable_map == other.callable_map
        end

        def [](callback_key)
          callable_map[callback_key]
        end

        def to_hash
          callable_map.dup
        end

        def merge(other)
          self.class.new(
            callable_map.merge( other.to_hash )
          )
        end

        def call(callback_key, *args)
          callback = callable_map[callback_key]
          callback.call *args if callback
        end

        protected

        attr_reader :callable_map
      end

    end
  end
end
