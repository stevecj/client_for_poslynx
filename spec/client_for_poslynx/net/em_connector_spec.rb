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

            it "reports success" do
              expect( on_success ).to receive(:call)
              @handler_instance.connection_completed
            end

            it "reports failure" do
              expect( on_failure ).to receive(:call)
              @handler_instance.unbind
            end
          end

        end

      end
    end
  end

end
