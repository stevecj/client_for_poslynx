# coding: utf-8

module ClientForPoslynx
  module Net
    class EM_Connector

      class ConnectionHandler < EM::Connection
        include EM::Protocols::POSLynx
        include EMC::HandlesConnection
      end

    end
  end
end
