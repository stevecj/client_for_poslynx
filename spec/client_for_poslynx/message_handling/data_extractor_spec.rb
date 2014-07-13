# coding: utf-8

require 'spec_helper'

module ClientForPoslynx

  describe MessageHandling::DataExtractor do
    subject{ described_class.new( xml_message_source ) }
    let( :xml_message_source ) { double( :xml_message_source ) }

    it "returns data objects for XML messages retrieved from source" do
      # In the real world, one stream would never contain both requests and
      # responses, but doing so here is a handy way to cover all behaviors.
      allow( xml_message_source ).to receive( :get_message )
        .and_return(
          "<PLRequest><Command>CCSALE</Command><Amount>50.00</Amount></PLRequest>",
          "<PLResponse><Command>PPINIT</Command><Result>Success</Result></PLResponse>",
        )

      results = 2.times.map{ subject.get_data }

      expect( results.first.amount ).to eq( '50.00' )
      expect( results.last.result  ).to eq( 'Success' )
    end

  end

end
