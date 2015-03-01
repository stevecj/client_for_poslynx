# coding: utf-8

module ClientForPoslynx
  module Net
    class EM_Connector

      module HandlesConnection
        def initialize(opts)
          connection_setter = opts.fetch(:connection_setter)
          connection_setter.call self
          @state_setter = opts.fetch(:state_setter)
          state_setter.call :connecting
        end

        attr_writer :event_dispatcher

        def reset_event_dispatcher
          self.event_dispatcher = nil
        end

        def connection_completed
          state_setter.call :connected
          event_dispatcher.event_occurred :connection_completed
        end

        def unbind
          state_setter.call :disconnected
          event_dispatcher.event_occurred :unbind
        end

        private

        attr_reader :state_setter

        def event_dispatcher
          @event_dispatcher ||= EM_Connector::EventDispatcher.null( self )
        end
      end

    end
  end
end
