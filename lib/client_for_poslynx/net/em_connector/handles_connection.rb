# coding: utf-8

module ClientForPoslynx
  module Net
    class EM_Connector

      module HandlesConnection
        def initialize(connector_state)
          @connector_state = connector_state
          connector_state.connection = self
          connector_state.connection_status = :connecting
        end

        attr_writer :event_dispatcher

        def event_dispatcher
          @event_dispatcher ||= EM_Connector::EventDispatcher.null( self )
        end

        def reset_event_dispatcher
          self.event_dispatcher = nil
        end

        def connection_completed
          connector_state.connection_status = :connected
          event_dispatcher.event_occurred :connection_completed
        end

        def unbind
          connector_state.connection_status = :disconnected
          event_dispatcher.event_occurred :unbind
        end

        private

        attr_reader :connector_state

      end

    end
  end
end
