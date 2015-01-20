# coding: utf-8

require 'spec_helper'
require 'stringio'

module ClientForPoslynx

  describe Net::EM_SessionClient do
    subject{ described_class.new(
      :the_host, :the_port,
      em_system: em_system,
      connection_base_class: connection_base_class,
    ) }

    let( :em_system ) { double( :em_system ) }

    let( :connection_base_class ) { Class.new do
      class << self
        attr_accessor :instantiated_count

        def new(*args)
          instance = super
          self.instantiated_count += 1
          instance
        end

        def instantiated_count
          @@instantiated_count ||= 0
        end

        def instantiated_count=(value)
          @@instantiated_count = value
        end
      end
    end }

    let( :connection_handlers ) { [] }

    before do
      allow( em_system ).to receive :connect do |host, port, handler_class, *handler_args|
        expect( host ).to eq( :the_host )
        expect( port ).to eq( :the_port )
        handler = handler_class.new( *handler_args )
        connection_handlers << handler
      end
    end

    describe "#start_session" do
      let( :on_connected         ) { double( :on_connected, :call => nil ) }
      let( :on_failed_connection ) { double( :on_failed_connection, :call => nil ) }

      it "Reports error on failure to connect" do
        subject.start_session(
          connected:         on_connected,
          failed_connection: on_failed_connection,
        )
        connection_handlers[0].unbind

        expect( on_connected         ).not_to have_received( :call )
        expect( on_failed_connection ).to     have_received( :call )
      end

      it "Reports connection on establishment of initial connection" do
        expect{
          subject.start_session(
            connected:         on_connected,
            failed_connection: on_failed_connection,
          )
        }.to change{
          connection_base_class.instantiated_count
        }.by 1

        connection_handlers[0].post_init

        expect( on_connected         ).to     have_received( :call )
        expect( on_failed_connection ).not_to have_received( :call )
      end

      it "Reports conection when already currently connected" do
        subject.start_session
        connection_handlers[0].post_init

        expect{
          subject.start_session(
            connected:         on_connected,
            failed_connection: on_failed_connection,
          )
        }.not_to change {
          connection_base_class.instantiated_count
        }

        expect( on_connected         ).to     have_received( :call )
        expect( on_failed_connection ).not_to have_received( :call )
      end

      it "Reports conection on establishment of new connection following disconnect" do
        subject.start_session
        connection_handlers[0].post_init
        connection_handlers[0].unbind

        expect{
          subject.start_session(
            connected:         on_connected,
            failed_connection: on_failed_connection,
          )
        }.to change {
          connection_base_class.instantiated_count
        }.by 1

        connection_handlers[1].post_init

        expect( on_connected         ).to     have_received( :call )
        expect( on_failed_connection ).not_to have_received( :call )
      end

    end

    describe "session" do
      it "can send request to POSLynx" do
        session = nil
        subject.start_session connected: ->(sess){
          session = sess
        }
        connection_handlers[0].post_init
        allow( connection_handlers[0] ).to receive( :send_request )
        session.send_request :the_request
        expect( connection_handlers[0] ).
          to have_received( :send_request ).
          with( :the_request )
      end

      describe '#send_request' do
        let( :connected_listener ) {
          cl = double( :connected_listener )
          allow( cl ).to receive( :call ) do |session|
            @session = session
          end
          cl
        }

        attr_reader :session

        before do
          subject.start_session connected: connected_listener
        end

        it "calls back to response listener when response received" do
          connection_handlers[0].post_init
          allow( connection_handlers[0] ).to receive( :send_request )
          response = nil
          session.send_request :the_request, responded: ->(sess, resp){
            response = resp
          }
          connection_handlers[0].receive_response :the_response
          expect( response ).to eq( :the_response )
        end

        it "transparently reconnects following connection close during session" do
          connection_handlers[0].post_init
          connection_handlers[0].unbind
          response = nil
          session.send_request :the_request, responded: ->(sess, resp){
            response = resp
          }
          allow( connection_handlers[1] ).to receive( :send_request )
          connection_handlers[1].post_init
          expect( connection_handlers[1] ).
            to have_received( :send_request ).
            with :the_request
          connection_handlers[1].receive_response :the_response
          expect( response ).to eq( :the_response )
        end
      end

      # TODO:
      # - Receive failure callback when connection is lost while response
      #   is pending.
      # - Correlate request/response types to distinguish between a session
      #   being supplanted and the new session that is supplanting it.
      # - Provide a means of callback for error during request send process,
      #   including error trying to re-connect before request or connection
      #   lost between send & receive.
    end

  end

end
