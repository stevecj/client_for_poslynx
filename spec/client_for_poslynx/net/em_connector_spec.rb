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
      let( :em_system ) { double( :em_system ) }
      let( :em_connection_base_class ) { Class.new do ; end }

      context "with SSL" do
        subject{ described_class.new(
          :the_host, :the_port,
          use_ssl: true,
          em_system: em_system,
          em_connection_base_class: em_connection_base_class,
        ) }

        it "initiates a secure connection" do
          expect( em_system ).to receive( :connect ) { |*args|
            expect( args.length ).to eq( 4 )
            host, port, handler, listener = args

            expect( host ).to eq( :the_host )
            expect( port ).to eq( :the_port )
            expect( handler ).to eq( subject.connection_class )
            expect( listener ).to respond_to( :to_em_connector_callback_adapter )
            @connection_handler = handler.new( listener )
          }

          subject.connect

          expect( @connection_handler ).to receive( :start_tls ).with( verify_peer: false )

          @connection_handler.connection_completed
        end

        context "with response" do
          let( :callback ) { double( :callback ) }

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

          context "on successful http connection" do
            before do
              allow( @connection_handler ).to receive( :start_tls )
              @connection_handler.connection_completed
            end

            it "calls back with connection handler and success on successful ssl start" do
              @connection_handler.ssl_handshake_completed
              expect( @success ).to eq( true )
            end

            it "calls back with connection handler and failure on ssl failure" do
              @connection_handler.unbind
              expect( @success ).to eq( false )
            end
          end

          context "on http connection failure" do
            before do ; @connection_handler.unbind ; end

            it "calls back with connection handler and failure" do
              expect( @success ).to eq( false )
            end
          end
        end

      end

      context "without SSL" do
        subject{ described_class.new(
          :the_host, :the_port,
          use_ssl: false,
          em_system: em_system,
          em_connection_base_class: em_connection_base_class,
        ) }

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

        context "with result" do
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
              subject.connection_class.new( subject._event_listener )
            }

            before do
              subject._event_listener.connection_completed connection_handler
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
              subject.connection_class.new( subject._event_listener )
            }

            before do
              subject._event_listener.connection_completed connection_handler_1
              subject._event_listener.unbind               connection_handler_1

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

    describe '#send_request' do
      subject{ described_class.new(
        :the_host, :the_port,
        use_ssl: false,
        em_system: em_system,
        em_connection_base_class: em_connection_base_class,
      ) }

      let( :em_system ) { double( :em_system ) }
      let( :em_connection_base_class ) { Class.new do ; end }
      let( :callback ) { double( :callback ) }

      before do
        allow( em_system ).to receive( :connect ) { |*args|
          host, port, handler, listener = args
          @connection_handler = handler.new( listener )
        }
      end

      context "without a current connection handler" do
        context "with result" do
          it "calls back with a nil response and a false connected status" do
            expect( callback ).to receive( :call ).with( nil, false )
            subject.send_request :the_request, callback
          end
        end
      end

      context "with a connection handler" do
        before do
          subject.connect
          @connection_handler.connection_completed
        end

        context "and the connection has not already been lost" do
          it "sends the given request using the current connection" do
            expect( @connection_handler ).to receive( :send_request ).with( :the_request )
            subject.send_request :the_request
          end

          context "with result" do
            it "calls back with the response and a true connected status" do
              allow( @connection_handler ).to receive( :send_request ).with( :the_request )
              subject.send_request :the_request, callback

              expect( callback ).to receive( :call ).with( :the_response, true )
              @connection_handler.receive_response :the_response
            end
          end
        end

        context "and the connection has already been lost" do
          before do
            @connection_handler.unbind
          end

          context "with result" do
            it "calls back with a nil response and a false connected status" do
              expect( callback ).to receive( :call ).with( nil, false )
              subject.send_request :the_request, callback
            end
          end
        end
      end
    end

  end

end
