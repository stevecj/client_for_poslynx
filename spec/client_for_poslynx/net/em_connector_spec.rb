# coding: utf-8

require 'spec_helper'
require 'stringio'

module ClientForPoslynx

  describe Net::EM_Connector do

    describe "default initialization not using SSL" do
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

        before do
          allow( em_system ).to receive( :connect ) { |*args|
            host, port, connection_class, *init_args = args
            @connection_handler = connection_class.new( *init_args )
          }

          subject.connect callback

          expect( callback ).to receive( :call ) do |handler, success|
            expect( handler ).to be_kind_of( subject.connection_class )
            expect( success ).to eq( expect_success )
          end
        end

        context "when connects successfully" do
          let( :expect_success ) { true }

          it "calls back with connection handler and success" do
            @connection_handler.connection_completed
          end
        end

        context "when fails to connect" do
          let( :expect_success ) { false }

          it "calls back with connection handler and failure" do
            @connection_handler.unbind
          end
        end
      end
    end
  end

end
