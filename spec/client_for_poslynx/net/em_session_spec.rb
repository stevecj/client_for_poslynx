# coding: utf-8

require 'spec_helper'

module ClientForPoslynx

  describe Net::EM_Session do
    subject {
      described_class.new( connector )
    }
    let( :connector ) { double(
      :connector,
      status_of_request: nil,
      latest_request: nil,
    ) }

    it "allows making a request and returning the response" do
      expect( connector ).to receive( :connect ) do |opts|
        opts[:on_success].call
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

    it "raises an exception when making a request with an initial connection failure" do
      expect( connector ).to receive( :connect ) do |opts|
        opts[:on_failure].call
      end

      exception = nil
      subject.execute do |s|
        begin
          s.request( :the_request_data )
        rescue => ex
          exception = ex
        end
      end
      expect( exception ).to be_kind_of( Net::EM_Session::RequestError )
    end

    it "raises an exception when making a request that fails" do
      expect( connector ).to receive( :connect ) do |opts|
        opts[:on_success].call
      end
      allow( connector ).to receive( :send_request ) do |data, opts|
        opts[:on_failure].call
      end

      exception = nil
      subject.execute do |s|
        begin
          s.request( :the_request_data )
        rescue => ex
          exception = ex
        end
      end
      expect( exception ).to be_kind_of( Net::EM_Session::RequestError )
    end

    context "when an existing pin pad reset request is pending" do
      before do
        allow( connector ).to receive( :status_of_request ).and_return( :pending )
        allow( connector ).to receive( :latest_request ).and_return(
          [ prev_request_data, { on_failure: prev_on_failure} ]
        )
      end

      let( :prev_request_data ) {
        Data::Requests::PinPadReset.new
      }
      let( :prev_on_failure ) {
        double(:prev_on_failure, call: nil)
      }

      it "usurps the pending request when making a new pin pad reset request" do
        allow( connector ).to receive( :get_response ) do |opts|
          opts[:on_response].call :the_response
        end

        response = nil
        request_data = Data::Requests::PinPadReset.new
        subject.execute do |s|
          response = s.request( request_data )
        end
        expect( prev_on_failure ).to have_received( :call )
        expect( response ).to eq( :the_response )
      end
    end

  end

end
