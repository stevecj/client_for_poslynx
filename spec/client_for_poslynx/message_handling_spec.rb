# coding: utf-8

require 'spec_helper'
require 'stringio'

module ClientForPoslynx

  describe MessageHandling do
    it "creates a stream data extractor" do
      stream_text = <<-XML
<PLRequest><Command>CCSALE</Command><Amount>10.00</Amount></PLRequest>
<PLRequest><Command>CCSALE</Command><Amount>15.15</Amount></PLRequest>
      XML

      stream = StringIO.new( stream_text )
      extractor = subject.stream_data_extractor( stream )

      results = 2.times.map{ extractor.get_data }

      expect( results.first.amount ).to eq( '10.00' )
      expect( results.last.amount  ).to eq( '15.15' )
    end

    it "creates a stream data writer" do
      stream = StringIO.new

      writer = subject.stream_data_writer( stream )

      writer.put_data Data::Requests::CreditCardSale.new.tap{ |d|
        d.client_mac = '1234'
        d.amount = '9.99'
      }
      writer.put_data Data::Responses::PinPadInitialize.new.tap{ |d| 
        d.result = 'Success'
      }

      expected_output = <<-EOS
<PLRequest><Command>CCSALE</Command><ClientMAC>1234</ClientMAC><Amount>9.99</Amount></PLRequest>
<PLResponse><Command>PPINIT</Command><Result>Success</Result></PLResponse>
      EOS

      stream.rewind
      expect( stream.read ).to eq( expected_output )

    end

  end

end
