# coding: utf-8

module ClientForPoslynx
  module Net
    class EM_Connector

      module HandlesConnection
        attr_reader :event_listener

        def initialize(event_listener)
          @event_listener = event_listener
        end

        def connection_completed
          event_listener.connection_completed self
        end
      end

    end
  end
end
