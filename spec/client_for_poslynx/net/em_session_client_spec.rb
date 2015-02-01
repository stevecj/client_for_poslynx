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

    let( :em_system ) {
      double( :em_system ).tap { |ems|
        allow( ems ).to receive :connect do |host, port, handler_class, *handler_args|
          expect( host ).to eq( :the_host )
          expect( port ).to eq( :the_port )
          handler = handler_class.new( *handler_args )
          connection_handlers << handler
        end
      }
    }

    let( :connection_handlers ) { [] }

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

    describe "#start_session" do
      let( :on_connected         ) { double( :on_connected, :call => nil ) }
      let( :on_failed_connection ) { double( :on_failed_connection, :call => nil ) }

      it "Reports error w/ session on failure to connect" do
        subject.start_session(
          connected:         on_connected,
          failed_connection: on_failed_connection,
        )
        connection_handlers[0].unbind

        expect( on_connected ).not_to have_received( :call )
        expect( on_failed_connection ).to have_received( :call ) { |session|
          expect( session ).to respond_to( :to_em_session )
        }
      end

      it "Reports connection w/ sesion on establishment of initial connection" do
        expect{
          subject.start_session(
            connected:         on_connected,
            failed_connection: on_failed_connection,
          )
        }.to change{
          connection_base_class.instantiated_count
        }.by 1

        connection_handlers[0].connection_completed

        expect( on_connected ).to have_received( :call ) { |session|
          expect( session ).to respond_to( :to_em_session )
        }
        expect( on_failed_connection ).not_to have_received( :call )
      end

      it "Reports conection w/ session when already currently connected" do
        subject.start_session
        connection_handlers[0].connection_completed

        expect{
          subject.start_session(
            connected:         on_connected,
            failed_connection: on_failed_connection,
          )
        }.not_to change {
          connection_base_class.instantiated_count
        }

        expect( on_connected         ).to     have_received( :call ) { |session|
          expect( session ).to respond_to( :to_em_session )
        }
        expect( on_failed_connection ).not_to have_received( :call )
      end

      it "Reports conection w/ session on establishment of new connection following disconnect" do
        subject.start_session
        connection_handlers[0].connection_completed
        connection_handlers[0].unbind

        expect{
          subject.start_session(
            connected:         on_connected,
            failed_connection: on_failed_connection,
          )
        }.to change {
          connection_base_class.instantiated_count
        }.by 1

        connection_handlers[1].connection_completed

        expect( on_connected         ).to     have_received( :call ) { |session|
          expect( session ).to respond_to( :to_em_session )
        }
        expect( on_failed_connection ).not_to have_received( :call )
      end

      #TODO: Test for both non-SSL and SSL cases. Probably make that distinction
      #      in HandlesConnection and test that separately.
    end

    describe "session" do
      def new_session
        result = nil
        subject.start_session connected: ->(session) {
          result = session
        }
        connection_handlers[0].connection_completed
        result
      end

      describe '#send_request' do
        let!( :session ) {
          new_session
        }

        it "sends request to POSLynx" do
          allow( connection_handlers[0] ).to receive( :send_request )

          session.send_request :the_request

          expect( connection_handlers[0] ).
            to have_received( :send_request ).
            with( :the_request )
        end

        it "calls back to response listener when response received" do
          allow( connection_handlers[0] ).to receive( :send_request )
          response = nil
          session.send_request :the_request, responded: ->(resp){
            response = resp
          }
          connection_handlers[0].receive_response :the_response
          expect( response ).to eq( :the_response )
        end

        it "transparently reconnects following connection close during session" do
          connection_handlers[0].unbind
          response = nil
          session.send_request :the_request, responded: ->(resp){
            response = resp
          }
          allow( connection_handlers[1] ).to receive( :send_request )
          connection_handlers[1].connection_completed
          expect( connection_handlers[1] ).
            to have_received( :send_request ).
            with :the_request
          connection_handlers[1].receive_response :the_response
          expect( response ).to eq( :the_response )
        end

        it "reports failure and closes session when re-opening connection fails" do
          connection_handlers[0].unbind
          response = nil
          failed_listener = double( :failed_listener, call: nil )
          session.send_request(
            :the_request,
            responded: double( :responded_listener ),
            failed: failed_listener
          )
          connection_handlers[1].unbind
          expect( failed_listener ).to have_received( :call )
        end

        it "reports failure and closes session when connection closed before response returned" do
          failed_listener = double( :failed_listener, call: nil )
          allow( connection_handlers[0] ).to receive( :send_request )
          session.send_request :the_request, failed: failed_listener
          connection_handlers[0].unbind
          expect( failed_listener ).to have_received :call
          expect( session ).to be_closed
        end
      end

      # TODO:
      # - Correlate request/response types to distinguish between a session
      #   being supplanted and the new session that is supplanting it.
    end

  end

end
