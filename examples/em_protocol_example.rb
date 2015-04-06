require 'client_for_poslynx'

SERVER_IP   = '192.168.1.25'
SERVER_PORT =  12345
CLIENT_MAC  = '000000000000'
USE_SSL     =  true

class ButtonSelectionDemo < EM::Connection
  include EM::Protocols::POSLynx

  def connection_completed
    puts "IP connection has been opened"
    if USE_SSL
      puts "Starting SSL"
      start_tls verify_peer: false
    else
      puts "Using raw connection. No SSL"
      display_the_message
    end
  end

  def ssl_handshake_completed
    puts "SSL session has been successfully started"
    display_the_message
  end

  def display_the_message
    puts "Sending the PIN Pad Display Message request"

    req = ClientForPoslynx::Data::Requests::PinPadDisplayMessage.new
    req.client_mac = CLIENT_MAC
    req.line_count = 2
    req.text_lines = [
      "Heads, we clean the basement",
      "Tails, we go to the movies"
    ]
    req.button_labels = %w[ Heads Tails ]

    send_request req
  end

  def receive_response(response)
    puts "Received response from POSLynx"
    puts "Result text:     #{response.result_text}"
    puts "Selected button: #{response.button_response}"

    puts "Closing the connection"
    close_connection
  end

  def unbind
    puts "The connection has been closed"
    puts "Terminating the event loop"
    EM.stop_event_loop
  end

end

# This code will block until the event loop exits.
EM.run do
  EM.connect SERVER_IP, SERVER_PORT, ButtonSelectionDemo
  EM.error_handler do |e|
    raise e
  end
end

puts "The event loop has ended"
puts "Bye"

# == Sample output ==
# IP connection has been opened
# Starting SSL
# SSL session has been successfully started
# Sending the PIN Pad Display Message request
# Received response from POSLynx
# Result text:     Success
# Selected button: Tails
# Closing the connection
# The connection has been closed
# Terminating the event loop
# The event loop has ended
# Bye
