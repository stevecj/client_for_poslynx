# coding: utf-8

require 'spec_helper'
require 'stringio'

module ClientForPoslynx

  describe MessageHandling do
    it 'creates a stream data extractor' do
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

  end

end
