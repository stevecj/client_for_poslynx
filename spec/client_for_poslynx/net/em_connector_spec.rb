# coding: utf-8

require 'spec_helper'
require 'stringio'

module ClientForPoslynx

  describe Net::EM_Connector do

    describe "with default dependencies" do
      subject{ described_class.new(:the_host, :the_port) }

      it "uses EM as the event-manager system" do
        expect( subject.em_system ).to eq( EM )
      end

      it "uses a connection class derived from EM::Connection" do
        expect( subject.connection_class.ancestors ).to include( EM::Connection )
      end
    end

    describe '#connect' do
      subject{ described_class.new(
        :the_host, :the_port,
        em_system: em_system,
        em_connection_base_class: em_connection_base_class,
      ) }

      let( :em_system ) { double( :em_system ) }
      let( :em_connection_base_class ) { Class.new do ; end }

      it "initiates a connection" do
        allow( em_system ).to receive( :connect )

        subject.connect

        expect( em_system ).to have_received( :connect ) { |*args|
          expect( args.length ).to eq( 4 )
          host, port, handler, listener = args

          expect( host ).to eq( :the_host )
          expect( port ).to eq( :the_port )
          expect( handler ).to eq( subject.connection_class )
          expect( listener ).to respond_to( :to_em_connector_callback_adapter )
        }
      end

      context "with response" do
        let( :callback ) { double( :callback ) }

        context "on initial connection attempt" do
          before do
            allow( em_system ).to receive( :connect ) { |*args|
              host, port, connection_class, *init_args = args
              @connection_handler = connection_class.new( *init_args )
            }

            subject.connect callback

            expect( callback ).to receive( :call ) do |handler, success|
              expect( handler ).to eq( @connection_handler )
              @success = success
            end
          end

          it "calls back with connection handler and success on successful connection" do
            @connection_handler.connection_completed
            expect( @success ).to eq( true )
          end

          it "calls back with connection handler and failure on connection failure" do
            @connection_handler.unbind
            expect( @success ).to eq( false )
          end
        end

        context "with an existing connection" do
          let( :connection_handler ) { 
            subject.connection_class.new( subject.event_listener )
          }

          before do
            subject.event_listener.connection_completed connection_handler
          end

          it "calls back with existing connection handler and success" do
            expect( callback ).to receive( :call ) do |handler, success|
              expect( handler ).to eq( connection_handler )
              @success = success
            end

            subject.connect callback
          end

        end

        context "with a previously closed connection" do
          let( :connection_handler_1 ) { 
            subject.connection_class.new( subject.event_listener )
          }

          before do
            subject.event_listener.connection_completed connection_handler_1
            subject.event_listener.unbind               connection_handler_1

            allow( em_system ).to receive( :connect ) { |*args|
              host, port, connection_class, *init_args = args
              @new_connection_handler = connection_class.new( *init_args )
            }

            subject.connect callback

            expect( callback ).to receive( :call ) do |handler, success|
              @received_connection_handler = handler
              @success = success
            end
          end

          it "calls back with new connection handler and success on successful connection" do
            @new_connection_handler.connection_completed
            expect( @received_connection_handler ).to eq( @new_connection_handler )
            expect( @success ).to eq( true )
          end

          it "calls back with new connection handler and failure on connection failure" do
            @new_connection_handler.unbind
            expect( @received_connection_handler ).to eq( @new_connection_handler )
            expect( @success ).to eq( false )
          end
        end
      end
    end
  end

end
