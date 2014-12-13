# coding: utf-8

require 'spec_helper'
require 'stringio'

module ClientForPoslynx

  describe EM::Protocols::POSLynx do
    let( :connection_class ) {
      subj = subject
      connection_class =
        Class.new do
          include subj

          def send_data(data) ; end
        end
    }

    let( :connection ) { connection_class.new }

    it "sends a request" do
      request = Data::Requests::PinPadDisplayMessage.new.tap do |req|
        req.client_mac = 'cdef'
      end

      expect( connection ).to receive( :send_data ){ |serial_data|
        got_data = Data::AbstractData.xml_parse( serial_data )
        expect( got_data ).to be_kind_of( Data::Requests::PinPadDisplayMessage )
        expect( got_data.client_mac ).to eq( 'cdef' )
      }

      connection.send_request request
    end
  end

end
