module ClientForPoslynx
  module HasClientConsoleSupport

    class ResponseReadyMonitor
      def self.ready?(conn)
        new( conn ).ready?
      end

      def initialize(conn)
        self.conn = conn
      end

      def ready?
        # Wait up to 1 second for data ready to read or error.
        ready = !! IO.select( [conn.io], [], [conn.io], 1 )
        return true if ready

        puts "Waiting for response. Press Enter to cancel."
        print "Waiting: "
        while true do
          print '.'

          # Wait up to 1 second for data or line of input from user.
          select_state = IO.select( [conn.io, $stdin], [], [conn.io], 1 )
          next unless select_state

          read_state, _, error_state = select_state
          any_state = read_state + error_state

          ( ready = true ; break ) if any_state.any? { |io| conn === io }
          ( gets         ; break ) if read_state.include?( $stdin )
        end
        puts

        ready
      end

      private

      attr_accessor :conn
    end

  end
end
