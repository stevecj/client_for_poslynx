# ClientForPoslynx

Note that this is currently a work in progress and is not
yet ready for use. It is actively under development though,
so check back in the near future if interested.

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

## Installation

Add this line to your application's Gemfile:

    gem 'client_for_poslynx'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install client_for_poslynx

## Usage

For example usage code, see the
lib/client_for_poslynx/has_client_colsole_support.rb file.

## Contributing

1. Fork it ( https://github.com/[my-github-username]/client_for_poslynx/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
