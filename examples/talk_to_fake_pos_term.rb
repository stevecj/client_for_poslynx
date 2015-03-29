# Given that fake_pos_terminal is running on the local system and
# listening on port 3010, this example will display a message
# with buttons on the terminal, and after a button is selected,
# will display info from the button response.
#
# This example will work equally well with an actual POSLynx and
# PIN pad if you change the IP address, port number, SSL, and
# client MAC values as appropriate.

SERVER_IP = '127.0.0.1'
SERVER_PORT = 3010
#TODO: Oops. We don't have SSL support built into EM_Connector yet.
CLIENT_MAC = 'whatever'


gem 'client_for_poslynx'
require 'client_for_poslynx'

include ClientForPoslynx::Net
include ClientForPoslynx::Data

connector = EM_Connector.new(SERVER_IP, SERVER_PORT)

EventMachine.run do

  EM_Session.execute connector do |s|
    request_data = Requests::PinPadDisplayMessage.new.tap{ |r|
      r.client_mac = CLIENT_MAC
      r.line_count = 2
      r.text_lines = ["How done", "do you want it"]
      r.button_labels = %w(Rare Medium Well-done)
    }
    response = s.request( request_data )

    request_data = Requests::PinPadDisplayMessage.new.tap{ |r|
      r.client_mac = CLIENT_MAC
      r.line_count = 2
      r.text_lines = [
        "Got result: #{response.result}",
        "Got button response: #{response.button_response}"
      ]
    }

    s.request request_data

    EventMachine.stop_event_loop
  end

end
