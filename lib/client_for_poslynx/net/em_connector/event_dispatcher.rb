# coding: utf-8

module ClientForPoslynx
  module Net
    class EM_Connector

      class EventDispatcher
        NULL_LISTENER = ->() { }

        class << self
          private :new

          def null(connection)
            new( connection )
          end

          def for_connect(connection, opts)
            new( connection ) do |d|
              d[:connection_completed] = opts[:on_success] if opts.key?(:on_success)
              d[:unbind]               = opts[:on_failure] if opts.key?(:on_failure)
            end
          end

          def for_disconnect(connection, opts)
            new( connection ) do |d|
              d[:unbind] = opts[:on_completed] if opts.key?(:on_completed)
            end
          end
        end

        def initialize(connection)
          @connection = connection
          yield self if block_given?
        end

        def []=(event_type, callback)
          callback_map[event_type] = callback
        end

        def event_occurred(event_type)
          connection.reset_event_dispatcher
          callback_map[event_type].call
        end

        private

        attr_reader :connection

        def callback_map
          @callback_map ||= Hash.new( NULL_LISTENER )
        end
      end

    end
  end
end
