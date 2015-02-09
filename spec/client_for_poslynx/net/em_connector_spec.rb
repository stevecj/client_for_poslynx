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
      let( :callback ) { double( :callback ) }
      let( :em_connect_args ) { [] }

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

      it "Reports connection handler and success for a successful connection" do
        allow( em_system ).to receive( :connect ) { |*args| em_connect_args.replace args }

        subject.connect callback

        expect( callback ).to receive( :call ) do |handler, success|
          expect( handler ).to be_kind_of( subject.connection_class )
          expect( success ).to eq( true )
        end

        host, port, connection_class, *conn_handler_init_args = em_connect_args
        connection_handler = connection_class.new(*conn_handler_init_args)
        connection_handler.connection_completed
      end

      it "Reports connection handler and failure for a failed connection" do
        allow( em_system ).to receive( :connect ) { |*args| em_connect_args.replace args }

        subject.connect callback

        expect( callback ).to receive( :call ) do |handler, success|
          expect( handler ).to be_kind_of( subject.connection_class )
          expect( success ).to eq( false )
        end

        host, port, connection_class, *conn_handler_init_args = em_connect_args
        connection_handler = connection_class.new(*conn_handler_init_args)
        connection_handler.unbind
      end
    end
  end

end
