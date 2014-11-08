# ClientForPoslynx

A client library for Ruby applications to communicate with a
Precidia Technologies POSLynx (TM) payment appliance.

This library was not developed by or on behalf of Precidia
Technologies.

Features:

* Data models for requests and responses.
* Writing requests to output streams.
* Reading responses from input streams.
* A fake POSLynx appliance + PIN Pad script.
* A POSLynx client console script.

The best introduction to this gem is probably to play around with
with the POSLynx client console.  Assuming you have a POSLynx
unit with IP address 192.168.1.123, listening on port 54321, with
a registered client MAC of 000000000000, an example poslynx
client session might look like...

    $ bundle exec poslynx_client_console 173.195.60.144:14270 --client_mac=000000000000
    1.9.3-p545 :001 > req = poslynx_client.example_pin_pad_display_message_request
     => #<ClientForPoslynx::Data::Requests::PinPadDisplayMessage:0x007f941b4b1fe8 @client_mac="001C42E644FE", @text_lines=["First example line", "Second example line"], @line_count=2, @button_labels=["1st of optional buttons", "2nd button"]>
    1.9.3-p545 :002 > resp = poslynx_client.send_request(req)
    <?xml version="1.0" standalone="yes" ?><PLResponse><Command>PPDISPLAY</Command><Result>Success</Result><ResultText>Success</ResultText><Response>2nd button</Response></PLResponse>
     => #<ClientForPoslynx::Data::Responses::PinPadDisplayMessage:0x007f941b4b8230 @result="Success", @result_text="Success", @button_response="2nd button", @source_data="<?xml version=\"1.0\" standalone=\"yes\" ?><PLResponse><Command>PPDISPLAY</Command><Result>Success</Result><ResultText>Success</ResultText><Response>2nd button</Response></PLResponse>\r\n">

This gem also provides a fake POS/terminal application that you
can run in a separate console window when you are working without
the necessary access to an actual POSLynx unit and PIN pad.  To
start the fake POS/terminal listening on port 3010...

    bundle exec fake_pos_terminal 3010

If you then want to start the client console to interact with the
fake POS/terminal instance on the same machine...

    bundle exec poslynx_client_console :3010

## Usage

The code in the
lib/client_for_poslynx/has_client_console_support.rb file
provides a good example of how to use the facilities that this
gem provides.

Some releases may also include experimental features that must
be separately loaded by requiring "client_for_poslynx/experimental'.

## Known Limitations

* Only a subset of the possible messages and elements is supported.
  __More will be added. Contributions are welcome and encouraged. :)__
* Performs serialization of requests and parsing of responses, but
  does not encapsulate actually making TCP connections and requests.

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
