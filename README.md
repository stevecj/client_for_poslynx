# ClientForPoslynx

A client library for Ruby applications to communicate with a
Precidia Technologies POSLynx (TM) payment appliance.

This library was not developed by or on behalf of Precidia
Technologies.

Features:

* Data models for requests and responses.
* Signature image translation to SVG.
* Network interaction using via EventMachine.
* A fake POSLynx appliance + PIN Pad script.

## Overview

The `client_for_poslynx` gem provides layers of network adapters
(operating via EventMachine) that can be used to send requests to
a POSLynx unit and receive the responses to those requests.  The
gem also includes data models with XML
serialization/deserialization that are used by those network
adapters or may be used as part of another network adapter if you
prefer to write one of your own.

### Asynchronous Messaging

Message interaction with POSLynx is primarily synchronous, in
that the client application makes a request, and then waits for
for a response.  In any realistic integrated POS solution,
however, there are cases in which it is necessary to devaite from
the typical synchronous flow.

Let's say that a customer starts an interaction with the
terminal, gets an emergency call, and runs off without completing
the interaction. The client application cannot do anything to
cancel the interaction because it's still blocked waiting for a
response.

### EventMachine

[EventMachine](http://rubyeventmachine.com/) is a Ruby library
that supports asynchronous network I/O using event callbacks.
`client_for_poslynx` provides an EventMachine protocol to allow
sending requests and receiving responses over an EventMachine
connection as well as adapter layers to simplify event-based
interaction via the EventMachine protocol.

One caveat to basing the library around EventMachine is that it
forces developers to deal with the EventMachine workflow in their
applications.

### Data Models

The `client_for_poslynx` gem includes data model classes for
kinds of requests that can be made to the POSLynx as well as for
responses that can be received from the POSLynx in response to
requests.

Models can be converted to/from XML-format messages to be sent or
receive over a network connection to the POSLynx.

These models can be used with the EventManager-based
communication adapters that exist within the gem, or you can use
them independently (e.g. if you perfer to communicate with the
POSLynx using Ruby's standard TCP/IP networking facilities.

Additionally, a `SignatureImage` model is provided that can be
used to parse or build POSLynx-compatible signature data strings,
along with a facility for converting signature images to SVG for
printing or display.

### Fake POS Terminal

The `client_for_poslynx` gem includes a script that acts as a
fake POSLynx + PIN Pad.  This is useful when you are working
without access to an actual POSLynx and PIN Pad, and want to test
your client code and try out workflows.

## Usage

### Using the "Request" and "Response" Data Models
See
* [`abstract_data.rb`](lib/client_for_poslynx/data/abstract_data.rb)
* [`requests`](lib/client_for_poslynx/data/requests/)
* [`responses`](lib/client_for_poslynx/data/responses/)

### Using the `EM_Session` Adapter

[`EM_Session`](lib/client_for_poslynx/net/em_session.rb) is the
highest level adapter, and the one that you will most likely want
to use.  It hides the significant complexity of the lower-level
event-driven interaction behind a synchronous API.  Interruptions
to the flow are accommodated by allowing multiple sessions to be
active at the same time and for one to interrupt the other.  This
"magic" is accomplished through the use of Ruby fibers.

Code examples:
* [`em_session_basic_example.rb`](examples/em_session_basic_example.rb)
* [`em_session_interrupt_example.rb`](examples/em_session_interrupt_example.rb)

It is important to note that a session's code block runs on
EventMachine's event handling thread, and one of the core
principles of EventMachine is to **never block that thread**.  If
you need to perform any time-consuming or potentially blocking
operations in a session, you should run it in a
`Session#exec_dissociated` block (runs via `EventMachine.defer`).
If you need to pause for a specific amount of time, then you can
call the non-blocking `Session#sleep` (runs via
`EventMachine.add_timer`).

When one session is in progress, and a new session makes a
request, the new request will attempt to override any pending
request of the first session, and to "detach" the other session
so that any of its subsequent request attemtps will be rejected
and fail with an exception.

In order to avoid race conditions and to ensure that every
response that is received is returned to the session that made
the corresponding request, the following rules apply.

1. If one session has a pending request, a new session makes a
   different kind of request, and then a response to the
   **second** request is received, then the first session
   receives an exception, and the second session will have the
   response reurned.
2. If one session has a pending request, a new session makes a
   different kind of request, and then a response to the
   **first** request is received, then the first session will
   have that response returned and will be detached.  The second
   session continues waiting for the subsequent response (to its
   request).
2. If one session has a pending `PinPadReset` (`PPRESET`)
   request, and a new session makes a `PinPadReset` request, then
   the first session receives an exception, and the response is
   returned to the second session.
4. If one session makes a request other than a `PinPadReset`,
   and a new session makes a request of the same type, then the
   new session's request fails immediately with an exception.

An important consequence of the rules above is that if the first
request made by a new session is a `PinPadReset`, then it will
always be able to successfully interrupt any existing session.
If it starts with any other kind of request, however, then it has
the potential to fail as described in rule #4.

For that reason, you should generally start any session with a
Pin Pad Reset request, and only do otherwise if you have
considered the consequences with respect to the rules above.

### Using the `EM_Connector` adapter

[`EM_Connector`](lib/client_for_poslynx/net/em_connector.rb) is
a low-level abstraction around an `EventMachine` connection with
the [`POSLynx`](lib/client_for_poslynx/net/em_protocol.rb)
protocol module included.

The jobs of `EM_Connector` are...

1. Simplify the task of making sure that a connection is open and
   making a request via that connection.
2. Assist in keeping track of the state of pending requests.
3. Provide a simple API for specifying callbacks to specific
   attempts to connection or send a request.

### The `POSLynx` protocol for EventManager

[`POSLynx`](lib/client_for_poslynx/net/em_protocol.rb) is an
`EventMachine` protocol for sending and receiving POSLynx
requests and responses.

This protocol is utilized in the same manner as other typical
`EventManager` protocols, by defining a connection handler class
that inherits from `EM::Connection` and includes the
`EM::Protocols::POSLynx` module, and then passing that class as
the handler argument to `EventMachine.connect`.

Code in the handler can call `#send_request` to send a request
(an instance of a subclass of
`ClientForPoslynx::Data::Requests::AbstractRequest`) and can
override the `#receive_response` method to receive responses
(instances of subclasses of
`ClientForPoslynx::Data::Response::AbstractResponse`)

Code example:
* [`em_protocol_example.rb`](examples/em_protocol_example.rb)

### Using the `fake_pos_terminal` script

The `fake_pos_terminal` script runs a console-based facsimile of
a PIN pad connected to a POSLynx device, listening on a local TCP
port.  The script takes a single parameter indicating the port
number to listen on.

Under some circumstances, if you have installed the
`client_for_poslynx` gem using Bundler, you might need to use
`bundle exec` to run the script.

To run the script listening on port 3010 using `bundle exec`:

    $ bundle exec fake_pos_terminal 3010

To stop the script, send an interrupt signal by pressing Ctrl+C.

## Known Limitations

* Only a subset of the possible messages and elements is
  supported.  __More might be added. Contributions are welcome
  and encouraged. :)__

## Installation

Add this line to your application's Gemfile:

    gem 'client_for_poslynx'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install client_for_poslynx

## Contributing

1. Fork it ( `https://github.com/[my-github-username]/client_for_poslynx/fork` )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
