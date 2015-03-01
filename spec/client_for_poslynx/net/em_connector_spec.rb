# coding: utf-8

require 'spec_helper'

module ClientForPoslynx

  describe Net::EM_Connector do
    describe "default initialization" do
      subject { described_class.new( :the_host, :the_port ) }

      it "Has ::EM as its em_system" do
        expect( subject.em_system ).to eq( ::EM )
      end

      it "Has Net::EM_Connector::ConnectionHandler as its connection_handler" do
        expect( subject.handler ).to eq( Net::EM_Connector::ConnectionHandler )
      end
    end

    context "actions" do
      subject { described_class.new(
        :the_host, :the_port,
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
          allow( em_system ).to receive( :connect ) do |host, port, handler, *handler_args|
            @handler_instance = handler.new( *handler_args )
            nil
          end
        end

        let( :on_success ) { double(:on_success) }
        let( :on_failure ) { double(:on_failure) }

        context "initial connection" do
          it "tries to open an EM connection using the connector's handler class" do
            subject.connect

            expect( em_system ).to have_received( :connect ) do |host, port, handler, *handler_args|
              expect( host ).to eq( :the_host )
              expect( port ).to eq( :the_port )
              expect( handler ).to eq( handler_class )
            end
          end

          it "exposes the handler instance" do
            subject.connect
            expect( subject.connection ).to eq( @handler_instance )
          end

          context "handling results" do
            before do
              subject.connect(
                on_success: on_success,
                on_failure: on_failure 
              )
            end

            it "reports success when connected" do
              expect( on_success ).to receive(:call)
              @handler_instance.connection_completed
            end

            it "reports failure when unbound" do
              expect( on_failure ).to receive(:call)
              @handler_instance.unbind
            end

            it "does not report failure when unbound later after success" do
              allow( on_success ).to receive(:call)
              @handler_instance.connection_completed

              expect( on_failure ).not_to receive(:call)
              @handler_instance.unbind
            end
          end

        end

        context "when previously connected" do
          before do
            subject.connect
            @handler_instance.connection_completed
          end

          it "reports success when currently connected" do
            expect( on_success ).to receive( :call )
            subject.connect on_success: on_success, on_failure: on_failure
          end

          context "when not currently connected" do
            before do
              @handler_instance.unbind
            end

            it "reconnects" do
              expect( @handler_instance ).to receive( :reconnect ).with( :the_host, :the_port )
              subject.connect
            end

            it "reports success when connected" do
              allow( @handler_instance ).to receive( :reconnect )
              subject.connect on_success: on_success, on_failure: on_failure

              expect( on_success ).to receive( :call )
              @handler_instance.connection_completed
            end

            it "reports failure when unbound" do
              allow( @handler_instance ).to receive( :reconnect )
              subject.connect on_success: on_success, on_failure: on_failure

              expect( on_failure ).to receive( :call )
              @handler_instance.unbind
            end
          end
        end

      end

      describe '#disconnect' do
        let( :on_completed ) { double(:on_completed) }

        it "reports completion when never connected" do
          expect( on_completed ).to receive( :call )
          subject.disconnect on_completed: on_completed
        end

        context "when previously connected" do
          before do
            @handler_instance = nil
            allow( em_system ).to receive( :connect ) do |host, port, handler, *handler_args|
              @handler_instance = handler.new( *handler_args )
              nil
            end
            subject.connect
            @handler_instance.connection_completed
          end

          it "reports completion when not currently connected" do
            @handler_instance.unbind

            expect( on_completed ).to receive( :call )
            subject.disconnect on_completed: on_completed
          end

          context "when currently connected" do
            it "closes the open connection" do
              expect( @handler_instance ).to receive( :close_connection )
              subject.disconnect
            end

            it "reports completion when done disconnecting" do
              allow( @handler_instance ).to receive( :close_connection )
              subject.disconnect on_completed: on_completed

              expect( on_completed ).to receive( :call )
              @handler_instance.unbind
            end
          end

        end
      end
    end
  end

end
