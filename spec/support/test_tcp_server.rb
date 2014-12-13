require 'socket'
require 'timeout'
require 'delegate'

# Encapsulates a TCPServer instance that can be used by tests. Public methods
# are thread-safe.
module TestTCP_Server
  extend self

  class AcceptTimeoutError < StandardError
    def initialize(_)
      super "Timout occurred while waiting for inbound connection"
    end
  end

  class ServerThreadTimeoutError < StandardError
    def initialize(_)
      super "Timout occurred while waiting for the server connection thread to finish"
    end
  end

  class ClientThreadTimeoutError < StandardError
    def initialize(_)
      super "Timout occurred while waiting for the client thread to finish"
    end
  end

  # A wrapper around an IO object that adds soem convenience
  # methods.
  class ConnectionIO < SimpleDelegator

    # Waits until data is ready to be read before returning.
    # If the conneciton has an error before having data ready
    # to read from, then the appropriate exception is raised.
    def wait_readable
      rr, _, er = IO.select( [__getobj__], nil, [__getobj__] )

      # Cause the error to be raised if select says the
      # connection has an error.
      getbyte unless er.empty?
    end

    # Waits until the connection is ready tp be written to before
    # returning.
    # If the conneciton has an error before being ready to be
    # written to, then the appropriate exception is raised.
    def wait_writable
      _, wr, er = IO.select( nil, [__getobj__], [__getobj__] )

      # Cause the error to be raised if select says the
      # connection has an error.
      write ' ' unless er.empty?
    end

  end

  @mutex = Mutex.new

  # Ensure that the server is running, and return the port number
  # that it is bound to.
  def port
    server.connect_address.ip_port
  end

  # Within the client thread, passes the server's bound port
  # number and a log object to the callable client action.
  #
  # Concurrently, within another thread, waits for a server
  # connection, and then passes the connection IO (wrapped
  # within a TestTCP_Server::ConnectionIO instance - see above)
  # and a log object to the callable server_action.
  #
  # Waits for both threads to terminate before returning.
  #
  # A timeout will occur if the server has not received a
  # connection within 1 second or if either the client or
  # server action block takes longer than 1 second to run.
  #
  # Returns an array containing the sequence of log entries
  # that were written by the threads and/or as a result of
  # timeouts.
  def run_client_server_session(client_action, server_action)
    log_queue = Queue.new

    s_thread = accept_in_thread log_queue, server_action
    c_thread = new_client_thread log_queue, client_action

    s_thread.join
    c_thread.join

    [].tap do |array|
      array << log_queue.shift until log_queue.empty?
    end
  end

  # Ensures that the server is running, and then starts a thread
  # that waits for a client connection and then passes the
  # connection IO (wrapped within a TestTCP_Server::ConnectionIO
  # instance - see above) and the log to the callable action.
  #
  # If a connection is not received within 1 second, then
  # AcceptTimeoutError is raised.  If a connection is received,
  # and then the action call does not complete within 1 second,
  # then ServerThreadTimeoutError is raised.
  #
  # If a log argument is given, then any exceptions, including
  # timeouts, that occur within the thread are captured and
  # appended to the log using the << operator.  It is the
  # caller's responsibility to ensure that the log's <<
  # operator is thread-safe.
  def accept_in_thread(log = nil, action)
    s = server
    Thread.new do
      begin
        io = Timeout.timeout(1.0, AcceptTimeoutError) {
          s.accept
        }
        io = self::ConnectionIO.new( io )
        Timeout.timeout 1.0, TestTCP_Server::ServerThreadTimeoutError do
          action.call io, log
        end
      rescue StandardError => e
        raise unless log
        log << e
      ensure
        io.close if io
      end
    end
  end

  # Within a new thread, passes server's listening port number
  # and the log to the callable action.
  #
  # If the given block does not complete within 1 second, then
  # ClientThreadTimeoutError is raised.
  #
  # If a log argument is given, then any exceptions, including
  # timeouts, that occur within the thread are captured and
  # appended to the log using the << operator.  It is the
  # caller's responsibility to ensure that the log's <<
  # operator is thread-safe.
  def new_client_thread(log = nil, action)
    pt = port
    Thread.new do
      begin
        Timeout.timeout 5.0, TestTCP_Server::ClientThreadTimeoutError do
          action.call pt, log
        end
      rescue StandardError => e
        raise unless log
        log << e
      end
    end
  end

  private

  def server
    @mutex.synchronize {
      @server ||= TCPServer.new('127.0.0.1', 0)
    }
  end
end
