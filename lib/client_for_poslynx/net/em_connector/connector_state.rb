# coding: utf-8

module ClientForPoslynx
  module Net
    class EM_Connector

      class State < Struct.new( :connection, :connection_status, :status_of_request )

        def connection_initial? ; connection_status == :initial       ; end
        def connecting?         ; connection_status == :connecting    ; end
        def connected?          ; connection_status == :connected     ; end
        def disconnecting?      ; connection_status == :disconnecting ; end
        def disconnecting?      ; connection_status == :disconnected  ; end

        def request_initial?  ; status_of_request == :initial      ; end
        def request_pending?  ; status_of_request == :pending      ; end
        def got_response?     ; status_of_request == :got_response ; end
        def request_failed?   ; status_of_request == :failed       ; end

      end

    end
  end
end
