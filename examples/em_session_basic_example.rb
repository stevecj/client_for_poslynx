require 'client_for_poslynx'

# Given that fake_pos_terminal is running on the local system and
# listening on port 3010, this example will execute the following
# workflow...
#
# 1. Display a message on the PIN pad with buttons.
# 2. After a button is selected on the PIN pad, display a message
#    showing info about the button response for 5 seconds.
# 3. Reset the PIN pad.
#
# This example will also work using an actual POSLynx and PIN pad
# if the IP address, port number, encryption, and client MAC
# values are changed appropriately.

SERVER_IP = '127.0.0.1'
SERVER_PORT = 3010
# :none for no encryption. :use_ssl for SSL encryption.
ENCRYPTION = :none
CLIENT_MAC = 'whatever'


gem 'client_for_poslynx'
require 'client_for_poslynx'

include ClientForPoslynx::Net
include ClientForPoslynx::Data

connector = EM_Connector.new(SERVER_IP, SERVER_PORT, encryption: ENCRYPTION)

EventMachine.run do

  EM_Session.execute connector do |s|
    begin
      request_data = Requests::PinPadDisplayMessage.new.tap{ |r|
        r.client_mac = CLIENT_MAC
        r.line_count = 2
        r.text_lines = ["How done", "do you want it"]
        r.button_labels = %w(Rare Medium Well-done)
      }
      response = s.request( request_data )
      unless response.error_code == '0000'
        puts "Got failure response from 1st request"
        puts "Error code: #{response.error_code}. Result text: #(response.result}"
        return
      end

      request_data = Requests::PinPadDisplayMessage.new.tap{ |r|
        r.client_mac = CLIENT_MAC
        r.line_count = 2
        r.text_lines = [
          "Got result: #{response.result}",
          "Got button response: #{response.button_response}"
        ]
      }
      s.request request_data
      unless response.error_code == '0000'
        puts "Got failure response from 2nd request"
        puts "Error code: #{response.error_code}. Result text: #(response.result}"
        return
      end

      s.sleep 4

      request_data = Requests::PinPadReset.new.tap{ |r|
        r.client_mac = CLIENT_MAC
      }
      s.request request_data
      unless response.error_code == '0000'
        puts "Got failure response from concluding reset request"
        puts "Error code: #{response.error_code}. Result text: #(response.result}"
        return
      end

    rescue EM_Session::RequestError => e
      puts "An exception was encountered in the session"
      puts e.message

    ensure
      EventMachine.stop_event_loop

    end
  end

end
