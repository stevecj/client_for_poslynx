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
      let( :prev_on_failure ) { double(:prev_on_failure, call: nil) }

      it "usurps the pending request when making a new pin pad reset request" do
        allow( connector ).to receive( :get_response ) do |opts|
          opts[:on_response].call :the_response
        end

        response = nil
        subject.execute do |s|
          response = s.request( Data::Requests::PinPadReset.new )
        end

        expect( prev_on_failure ).to have_received( :call )
        expect( response ).to eq( :the_response )
      end
    end

    context "when a request is pending" do
      before do
        allow( connector ).to receive( :connection_status ).and_return( :connected )
        allow( connector ).to receive( :status_of_request ).and_return( :pending )
        allow( connector ).to receive( :latest_request ).and_return( [
          prev_request_data,
          {
            on_response:    prev_on_response,
            on_failure:    prev_on_failure,
            on_supplanted: prev_on_supplanted,
          }
        ] )
      end
      let( :prev_request_data ) { Data::Requests::PinPadInitialize.new }
      let( :prev_on_response   ) { double(:prev_on_response,   call: nil) }
      let( :prev_on_failure    ) { double(:prev_on_failure,    call: nil) }
      let( :prev_on_supplanted ) { double(:prev_on_supplanted, call: nil) }

      context "making a new request of the same type" do
        it "raises an appropriate exception" do
          request_data = Data::Requests::PinPadInitialize.new

          exception = nil
          subject.execute do |s|
            begin
              s.request( request_data )
            rescue => ex
              exception = ex
            end
          end

          expect( exception ).to be_kind_of( Net::EM_Session::ConflictingRequestError )
        end
      end

      context "making a new request of a different type" do
        it "supplants the pending request if possible" do
          request_data = Data::Requests::PinPadDisplayMessage.new
          response_data = Data::Responses::PinPadDisplayMessage.new
          allow( connector ).to receive( :connect ) do |opts|
            opts[:on_success].call
          end
          allow( connector ).to receive( :send_request ).with( request_data, anything ) do |data, opts|
            opts[:on_response].call response_data
          end

          response = nil
          subject.execute do |s|
            response = s.request( request_data )
          end

          expect( prev_on_failure ).to have_received( :call )
          expect( response ).to eq( response_data )
        end

        it "supplants the other event chain if supplanting the pending request is unsuccessful" do
          # FIXME: This is awfully convoluted, even by comparison
          #        with other examples in this spec file.
          allow( connector ).to receive( :connect ) do |opts|
            opts[:on_success].call
          end

          request_data = Data::Requests::PinPadDisplayMessage.new
          first_response_data = Data::Responses::PinPadInitialize.new
          second_response_data = Data::Responses::PinPadDisplayMessage.new

          expect( connector ).to receive( :send_request ).ordered.with( request_data, anything ) do |data, opts|
            opts[:on_response].call first_response_data
          end
          expect( prev_on_supplanted ).to receive( :call ).ordered
          expect( prev_on_response   ).to receive( :call ).ordered.with( first_response_data )
          expect( connector ).to receive( :get_response ).ordered do |opts|
            opts[:on_response].call second_response_data
          end

          response = nil
          subject.execute do |s|
            response = s.request( request_data )
          end

          expect( prev_on_failure ).not_to have_received( :call )
          expect( response ).to eq( second_response_data )
        end

        it "fails both the new and previously pending requests on request failure without response" do
          request_data = Data::Requests::PinPadDisplayMessage.new
          response_data = Data::Responses::PinPadInitialize.new
          allow( connector ).to receive( :connect ) do |opts|
            opts[:on_success].call
          end
          allow( connector ).to receive( :send_request ).with( request_data, anything ) do |data, opts|
            opts[:on_failure].call
          end

          exception = nil
          subject.execute do |s|
            begin
              s.request( request_data )
            rescue => ex
              exception = ex
            end
          end

          expect( prev_on_failure ).to have_received( :call )
          expect( exception ).to be_kind_of( Net::EM_Session::RequestError )
        end

      end

      context "when its event chain is supplanted during successful receipt of response" do
        it "continues to run and received the returned response"
        it "is blocked from making additional requests"
      end
    end

  end

end
