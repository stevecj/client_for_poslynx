# coding: utf-8

require 'spec_helper'

module ClientForPoslynx

  describe Net::EM_Session do
    subject {
      described_class.new( connector )
    }
    let( :connector ) { double(:connector) }

    it "allows making a request and returning the response" do
      expect( connector ).to receive( :connect ) do |opts|
        opts[:on_completed].call
      end
      allow( connector ).to receive( :send_request ) do |data, opts|
        opts[:on_response].call :the_response
      end

      response = nil
      subject.execute do |s|
        response = s.request( :the_request_data )
      end
      expect( response ).to eq( :the_response )
    end
  end

end
