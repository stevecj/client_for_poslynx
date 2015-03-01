# coding: utf-8

module ClientForPoslynx
  module Net
    class EM_Connector

      module HandlesConnection
        attr_reader :on_connect_success, :on_connect_failure

        def initialize(opts)
          connection_setter = opts.fetch(:connection_setter)
          connection_setter.call self
        end

        attr_writer :event_dispatcher

        def reset_event_dispatcher
          self.event_dispatcher = nil
        end

        def connection_completed
          event_dispatcher.event_occurred :connection_completed
        end

        def unbind
          event_dispatcher.event_occurred :unbind
        end

        private

        def event_dispatcher
          @event_dispatcher ||= EM_Connector::EventDispatcher.null( self )
        end
      end

    end
  end
end
