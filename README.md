# ClientForPoslynx

A client library for Ruby applications to communicate with a
Precidia Technologies POSLynx (TM) payment appliance.

This library was not developed by or on behalf of Precidia
Technologies.

Features:

* Data models for requests and responses.
* Network interaction using an EventMachine protocol.
* Simplified network interaction using a structured client
  adapter.
* A fake POSLynx appliance + PIN Pad script.

## Overview

The client_for_poslynx gem provides network adapters that can be
used to send requests to a POSLynx unit and receive the responses
to those requests.  The gem also includes data models with XML
serialization/deserialization that are used by those network
adapters or may be used as part of a different network adapter if
you prefer to build your own.

The first network adapter provided is in the form of a protocol
for EventMachine. EventMachine is a gem for implementing
event-driven communication clients and servers.  Essentially,
being event-driven means that requests are sent asynchronously,
and the application receives a call-back when the server
responds (or the connection is lost, etc.)

The second network adapter this gem provides is a "structured"
(as opposed to event-driven) API.  This is primarily provided
as a convenience for use in situations where the event-driven
API is inconvenient, such as when experimenting with the gem
from an irb command line session.

## Usage

### Using the structured client

A quick and easy way to try out this gem is to use the structured
client and example-request factory from an irb console.

Assuming you have a POSLynx host running at 192.168.1.99 on port
1234 with SSL required, and if your lane has a registered client
MAC value of 123456789ABC, then with the client_for_poslynx gem
installed, you should be able to execute a sequence similar to
the following.

    $ irb
    1.9.3-p545 :001 > require 'client_for_poslynx'
     => true
    1.9.3-p545 :002 > client = ClientForPoslynx::Net::StructuredClient.new('192.168.1.99', 1234, true)
     => #<ClientForPoslynx::Net::StructuredClient:0x007fefa2103aa8 @directive_queue=#<Queue:0x007fefa21039e0 @que=[], @waiting=[], @mutex=#<Mutex:0x007fefa2103968>>, @activity_queue=#<Queue:0x007fefa2103940 @que=[], @waiting=[], @mutex=#<Mutex:0x007fefa2103300>>, @em_thread=#<Thread:0x007fefa2103260 sleep>>
    1.9.3-p545 :003 > reqf = ClientForPoslynx::ExampleRequestFactory.new('1234567890ABC')
     => #<ClientForPoslynx::ExampleRequestFactory:0x007fefa2036030 @client_mac="1234567890ABC">
    1.9.3-p545 :004 > req = reqf.pin_pad_initialize_request
     => #<ClientForPoslynx::Data::Requests::PinPadInitialize:0x007fefa204f760 @client_mac="1234567890ABC", @idle_prompt="Example idle prompt">
    1.9.3-p545 :005 > client.send_request req
     => nil
    1.9.3-p545 :006 > client.get_response
     => #<ClientForPoslynx::Data::Responses::PinPadInitialize:0x007fefa21106e0 @result="Success", @result_text="PinPad Initialized", @error_code="1000", @source_data="<?xml version=\"1.0\" standalone=\"yes\" ?><PLResponse><Command>PPINIT</Command><Result>Success</Result><ResultText>PinPad Initialized</ResultText><ErrorCode>1000</ErrorCode></PLResponse>">
    1.9.3-p545 :007 > client.end_session
     => nil

### Using the EventMachine protocol

The following example code demonstrates how to write an
event-driven client using EventMachine and the POSLynx protocol
for EventMachine.

    require 'client_for_poslynx'
    
    HOST       = '192.168.1.25'
    PORT       =  12345
    CLIENT_MAC = '000000000000'
    USE_SSL    =  true
    
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
      EM.connect HOST, PORT, ButtonSelectionDemo
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

## Known Limitations

* Only a subset of the possible messages and elements is supported.
  __More will be added. Contributions are welcome and encouraged. :)__

## Installation

Add this line to your application's Gemfile:

    gem 'client_for_poslynx'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install client_for_poslynx

## Contributing

1. Fork it ( https://github.com/[my-github-username]/client_for_poslynx/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
