require 'client_for_poslynx'

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

session_a = ->(s) {
  begin
    request_data = Requests::PinPadDisplayMessage.new.tap{ |r|
      r.client_mac = CLIENT_MAC
      r.line_count = 2
      r.text_lines = ["How done", "do you want it"]
      r.button_labels = %w(Rare Medium Well-done)
    }
    response = s.request( request_data )
    unless response.error_code == '0000'
      puts "Got failure response in session_a from 1st request"
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
      puts "Got failure response in session_a from 2st request"
      puts "Error code: #{response.error_code}. Result text: #(response.result}"
      return
    end

    s.sleep 4

    request_data = Requests::PinPadReset.new.tap{ |r|
      r.client_mac = CLIENT_MAC
    }
    s.request request_data
    unless response.error_code == '0000'
      puts "Got failure response in session_b from concluding reset-request"
      puts "Error code: #{response.error_code}. Result text: #(response.result}"
      return
    end

    EventMachine.stop_event_loop

  rescue EM_Session::RequestError => e
    puts "An exception was encountered in session_a"
    puts e.message

  end
}

session_b = ->(s) {
  begin
    # Let session_a get underway before interrupting.
    s.sleep 3

    request_data = Requests::PinPadReset.new.tap{ |r|
      r.client_mac = CLIENT_MAC
    }
    response = s.request( request_data )
    unless response.error_code == '0000'
      puts "Got failure response in session_b from 1st request"
      puts "Error code: #{response.error_code}. Result text: #(response.result}"
      return
    end

    request_data = Requests::PinPadDisplayMessage.new.tap{ |r|
      r.client_mac = CLIENT_MAC
      r.line_count = 1
      r.text_lines = "Rudely interrupting..."
    }
    s.request request_data
    unless response.error_code == '0000'
      puts "Got failure response in session_b from 2nd request"
      puts "Error code: #{response.error_code}. Result text: #(response.result}"
      return
    end

    s.sleep 3

    request_data = Requests::PinPadDisplayMessage.new.tap{ |r|
      r.client_mac = CLIENT_MAC
      r.line_count = 2
      r.text_lines = ["How annoying was", "this interruption?"]
      r.button_labels = %w(Very Not-much)
    }
    response = s.request( request_data )
    unless response.error_code == '0000'
      puts "Got failure response in session_b from 3rd request"
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
      puts "Got failure response in session_b from 4th request"
      puts "Error code: #{response.error_code}. Result text: #(response.result}"
      return
    end

    s.sleep 4

    request_data = Requests::PinPadReset.new.tap{ |r|
      r.client_mac = CLIENT_MAC
    }
    s.request request_data
    unless response.error_code == '0000'
      puts "Got failure response in session_b from concluding reset-request"
      puts "Error code: #{response.error_code}. Result text: #(response.result}"
      return
    end

  rescue EM_Session::RequestError => e
    puts "An exception was encountered in session_b"
    puts e.message

  ensure
    EventMachine.stop_event_loop

  end
}

EventMachine.run do
  EM_Session.execute connector, &session_a
  EM_Session.execute connector, &session_b
end
