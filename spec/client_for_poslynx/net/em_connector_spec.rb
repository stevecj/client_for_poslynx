# coding: utf-8

require 'spec_helper'

module ClientForPoslynx

  describe Net::EM_Connector do
    describe "default initialization" do
      subject { described_class.new( :the_server, :the_port ) }

      it "Has ::EM as its em_system" do
        expect( subject.em_system ).to eq( ::EM )
      end

      it "Has Net::EM_Connector::ConnectionHandler as its connection_handler" do
        expect( subject.handler ).to eq( Net::EM_Connector::ConnectionHandler )
      end

      it "Sets the connection state to :initial" do
        expect( subject.connection_state ).to eq( :initial )
      end
    end

    context "actions and events" do
      subject { described_class.new(
        :the_server, :the_port,
        em_system: em_system,
        handler: handler_class
      ) }

      let( :em_system ) { double( :em_system ) }
      let( :handler_class ) { Class.new do
        include Net::EM_Connector::HandlesConnection
      end }

      describe '#connect' do
        before do
          @handler_instance = nil
          allow( em_system ).to receive( :connect ) do |server, port, handler, *handler_args|
            @handler_instance = handler.new( *handler_args )
            nil
          end
        end

        let( :on_success ) { double(:on_success, call: nil) }
        let( :on_failure ) { double(:on_failure, call: nil) }

        context "initial connection" do
          before do
            subject.connect on_success: on_success, on_failure: on_failure
          end

          it "tries to open an EM connection using the connector's handler class" do
            expect( em_system ).to have_received( :connect ) do |server, port, handler, *handler_args|
              expect( server ).to eq( :the_server )
              expect( port ).to eq( :the_port )
              expect( handler ).to eq( handler_class )
            end
          end

          it "exposes the handler instance" do
            expect( subject.connection ).to eq( @handler_instance )
          end

          it "sets the connection state to :connecting" do
            expect( subject.connection_state ).to eq( :connecting )
          end

          context "when connection is completed" do
            before do
              @handler_instance.connection_completed
            end

            it "reports success and not failure" do
              expect( on_success ).to     have_received( :call )
              expect( on_failure ).not_to have_received( :call )
            end

            it "sets the connection state to :connected" do
              expect( subject.connection_state ).to eq( :connected )
            end
          end

          context "when the connection attempt fails" do
            before do
              @handler_instance.unbind
            end

            it "reports failure and not success" do
              expect( on_failure ).to     have_received(:call)
              expect( on_success ).not_to have_received(:call)
            end

            it "sets the connection state to :disconnected" do
              expect( subject.connection_state ).to eq( :disconnected )
            end
          end

          context "following successful connection" do
            before do
              @handler_instance.connection_completed
            end

            it "does not report failure later when subsequently disconnected" do
              @handler_instance.unbind
              expect( on_failure ).not_to have_received(:call)
            end
          end
        end

        context "when previously connected" do
          before do
            # Establish previous connection.
            subject.connect
            @handler_instance.connection_completed
          end

          context "when currently connected" do
            before do
              subject.connect on_success: on_success, on_failure: on_failure
            end

            it "reports success and not failure" do
              expect( on_success ).to     have_received( :call )
              expect( on_failure ).not_to have_received( :call )
            end
          end

          context "when not currently connected" do
            before do
              @handler_instance.unbind
              allow( @handler_instance ).to receive( :reconnect )

              subject.connect on_success: on_success, on_failure: on_failure
              expect( on_success ).not_to have_received( :call )  # Sanity check.
            end

            it "reconnects" do
              expect( @handler_instance ).to have_received( :reconnect ).with( :the_server, :the_port )
            end

            it "reports success and not failure when connected" do
              @handler_instance.connection_completed
              expect( on_success ).to     have_received( :call )
              expect( on_failure ).not_to have_received( :call )
            end

            it "reports failure and not success when unbound" do
              @handler_instance.unbind
              expect( on_failure ).to     have_received( :call )
              expect( on_success ).not_to have_received( :call )
            end
          end
        end

      end

      context "when an open connection is lost or remotely disconnected" do
        before do
          @handler_instance = nil
          allow( em_system ).to receive( :connect ) do |server, port, handler, *handler_args|
            @handler_instance = handler.new( *handler_args )
            nil
          end
          subject.connect
          @handler_instance.connection_completed
          @handler_instance.unbind
        end

        it "sets the connection state to :disconnected" do
          expect( subject.connection_state ).to eq( :disconnected )
        end
      end

      describe '#disconnect' do
        let( :on_completed ) { double(:on_completed, call: nil) }

        context "when has never been connected" do
          before do
            allow( @handler_instance ).to receive( :close_connection )  # Sanity check.
            subject.disconnect on_completed: on_completed
            expect( @handler_instance ).not_to have_received( :close_connection )  # Sanity check.
          end

          it "reports completion" do
            expect( on_completed ).to have_received( :call )
          end

          it "leaves connection state as :initial" do
            expect( subject.connection_state ).to eq( :initial )
          end
        end

        context "when previously connected" do
          before do
            @handler_instance = nil
            allow( em_system ).to receive( :connect ) do |server, port, handler, *handler_args|
              @handler_instance = handler.new( *handler_args )
              nil
            end
            subject.connect
            @handler_instance.connection_completed
          end

          context "when not currently connected" do
            before do
              @handler_instance.unbind
              subject.disconnect on_completed: on_completed
            end

            it "reports completion" do
              expect( on_completed ).to have_received( :call )
            end

            it "leaves the connection state as :disconnected" do
              expect( subject.connection_state ).to eq( :disconnected )
            end
          end

          context "when currently connected" do
            before do
              allow( @handler_instance ).to receive( :close_connection )
              subject.disconnect on_completed: on_completed
            end

            it "closes the open connection" do
              expect( @handler_instance ).to have_received( :close_connection )
            end

            it "sets the connection state to :disconnecting" do
              expect( subject.connection_state ).to eq( :disconnecting )
            end

            context "when done disconnecting" do
              it "reports completion" do
                expect( on_completed ).not_to have_received( :call )  # Sanity check.
                @handler_instance.unbind
                expect( on_completed ).to have_received( :call )
              end

              it "sets the connection state to :disconnected" do
                @handler_instance.unbind
                expect( subject.connection_state ).to eq( :disconnected )
              end
            end
          end

        end
      end
    end
  end

end
