# coding: utf-8

module ClientForPoslynx
  module Net
    class EM_Connector

      module HandlesConnection
        attr_reader :on_connect_success, :on_connect_failure

        def initialize(opts)
          connection_setter = opts.fetch(:connection_setter)
          connection_setter.call self
          @on_connect_success = opts.fetch(:on_connect_success)
          @on_connect_failure = opts.fetch(:on_connect_failure)
        end

        def connection_completed
          on_connect_success.call
        end

        def unbind
          on_connect_failure.call
        end
      end

    end
  end
end
