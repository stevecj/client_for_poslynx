# coding: utf-8

require 'spec_helper'
require 'stringio'

module ClientForPoslynx

  describe Net::EM_Connector do

    shared_context "Simulates EM::connect()" do
      before do
        allow( em_system ).to receive( :connect ) { |*args|
          host, port, connection_class, *init_args = args
          @connection_handler = connection_class.new( *init_args )
        }
      end
    end

    describe "with default dependencies" do
      subject{ described_class.new(:the_host, :the_port) }

      it "uses EM as the event-manager system" do
        expect( subject.em_system ).to eq( EM )
      end

      it "uses a connection class derived from EM::Connection" do
        expect( subject.connection_class.ancestors ).to include( EM::Connection )
      end
    end

    describe "actions" do
      subject{ described_class.new(
        :the_host, :the_port,
        use_ssl: use_ssl,
        em_system: em_system,
        em_connection: { base_class: em_connection_base_class },
      ) }

      let( :em_system ) { double( :em_system ) }
      let( :em_connection_base_class ) { Class.new do ; end }

      let( :callback ) { double( :callback ) }

      describe '#connect' do

        context "without SSL" do
          include_context "Simulates EM::connect()"

          let( :use_ssl ) { false }

          it "initiates a connection" do
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
            context "on initial connection attempt" do
              before do
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

        context "with SSL" do
          let( :use_ssl ) { true }

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
            include_context "Simulates EM::connect()"

            before do
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
      end

      describe '#send_request' do
        include_context "Simulates EM::connect()"

        let( :use_ssl ) { false }

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

          context "and the connection has not already been and does not get lost" do
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

          context "and the connection is lost without first receiving a response" do
            it "calls back with a nil response and a false connected status" do
              allow( @connection_handler ).to receive( :send_request ).with( :the_request )
              subject.send_request :the_request, callback

              expect( callback ).to receive( :call ).with( nil, false )
              @connection_handler.unbind
            end
          end
        end
      end

      describe '#close_connection' do
        include_context "Simulates EM::connect()"

        let( :use_ssl ) { false }

        before do
          allow( em_system ).to receive( :connect ) { |*args|
            host, port, handler, listener = args
            @connection_handler = handler.new( listener )
          }
        end

        context "without a current connection handler" do
          context "with result" do
            it "calls back" do
              expect( callback ).to receive( :call ).with( no_args )
              subject.close_connection callback
            end
          end
        end

        context "with a connection handler" do
          before do
            subject.connect
            @connection_handler.connection_completed
          end

          context "and the connection has not already been lost" do
            it "forwards to #close_connection on the connection handler" do
              expect( @connection_handler ).to receive( :close_connection ).with( :some_options )
              subject.close_connection nil, :some_options
            end

            context "with result" do
              it "calls back when the connection has been terminated" do
                allow( @connection_handler ).to receive( :close_connection )
                subject.close_connection callback

                expect( callback ).to receive( :call ).with( no_args )
                @connection_handler.unbind
              end
            end

          end

          context "and the connection has already been lost" do
            before do
              @connection_handler.unbind
            end

            context "with result" do
              it "calls back" do
                expect( callback ).to receive( :call ).with( no_args )
                subject.close_connection callback
              end
            end
          end
        end

      end
    end

  end

end
