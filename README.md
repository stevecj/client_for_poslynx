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

    bundle exec poslynx_client_console 192.168.1.123:54321
    1.9.3-p545 :001 > poslynx_client.client_mac_for_examples = '0' * 12
     => "000000000000"
    1.9.3-p545 :002 > resp = poslynx_client.send_request( poslynx_client.example_pin_pad_display_message_request )
     => #<ClientForPoslynx::Data::Responses::PinPadDisplayMessage:0x007fbf529a17f8 @result="SUCCESS", @result_text="Success", @error_code="0000", @button_response="2nd button", @source_data="<PLResponse><Command>PPDISPLAY</Command><Result>SUCCESS</Result><ResultText>Success</ResultText><ErrorCode>0000</ErrorCode><Response>2nd button</Response></PLResponse>\n">

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
lib/client_for_poslynx/has_client_colsole_support.rb file
provides a good example of how to use the facilities that this
gem provides.

## Known Limitations

* Only a subset of the possible messages and elements is supported.
  __More will be added. Contributions are welcome and encouraged. :)__
* Performs serialization of requests and parsing of responses, but
  does not ecapsulate actually making TCP connections and requests.

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
