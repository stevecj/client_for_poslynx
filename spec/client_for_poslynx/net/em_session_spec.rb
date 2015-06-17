# coding: utf-8

require 'spec_helper'

module ClientForPoslynx

  describe Net::EM_Session do
    subject {
      described_class.new( connector, em_system: em_system )
    }
    let( :connector ) { double(
      :connector,
      request_pending?: false,
      latest_request: nil,
    ) }
    let( :em_system ) { double(:em_system) }

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
        allow( connector ).to receive( :request_pending? ).and_return( true )
        allow( connector ).to receive( :latest_request ).and_return(
          Net::EMC.RequestCall(
            prev_request_data, { on_failure: prev_on_failure}
          )
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
        allow( connector ).to receive( :request_pending? ).and_return( true )
        allow( connector ).to receive( :latest_request ).and_return(
          Net::EMC.RequestCall(
            prev_request_data,
            {
              on_response: prev_on_response,
              on_failure:  prev_on_failure,
              on_detached: prev_on_detached,
            }
          )
        )
      end
      let( :prev_request_data ) { Data::Requests::PinPadInitialize.new }
      let( :prev_on_response   ) { double(:prev_on_response,   call: nil) }
      let( :prev_on_failure    ) { double(:prev_on_failure,    call: nil) }
      let( :prev_on_detached ) { double(:prev_on_detached, call: nil) }

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

        it "detaches the other event chain if supplanting the pending request is unsuccessful" do
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
          expect( prev_on_detached ).to receive( :call ).ordered
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

      context "when its event chain is detached during successful receipt of response" do
        it "continues to run and receives the returned response" do
          expect( connector ).to receive( :connect ) do |opts|
            opts[:on_success].call
          end
          allow( connector ).to receive( :send_request ) do |data, opts|
            opts[:on_detached].call
            opts[:on_response].call :the_response
          end

          response = nil
          subject.execute do |s|
            response = s.request( :the_request_data )
          end

          expect( response ).to eq( :the_response )
        end

        it "is blocked from making additional requests" do
          expect( connector ).to receive( :connect ) do |opts|
            opts[:on_success].call
          end
          allow( connector ).to receive( :send_request ) do |data, opts|
            opts[:on_detached].call
            opts[:on_response].call :the_response
          end

          exception = nil
          subject.execute do |s|
            s.request( :the_request_data )
            begin
              s.request( :the_request_data )
            rescue Net::EM_Session::RequestError => ex
              exception = ex
            end
          end

          expect( prev_on_failure ).to have_received( :call )
          expect( exception ).to be_kind_of( Net::EM_Session::RequestAfterDetachedError )
        end
      end
    end

    context "executing a dissociated block" do
      before do
        allow( em_system ).to receive( :defer ) do |block, callback|
          result = block.call
          callback.call result
        end
      end

      it "gets the value returned from the code execution" do
        exec_result = nil
        subject.execute do |s|
          exec_result = subject.exec_dissociated {
            :the_result
          }
        end
        expect( exec_result ).to eq( :the_result )
      end

      it "gets the exception raised during the code execution" do
        exception = nil
        subject.execute do |s|
          begin
            subject.exec_dissociated do
              raise 'the error'
            end
          rescue => e
            exception = e
          end
        end
        expect( exception ).to be_kind_of( StandardError )
        expect( exception.message ).to eq( 'the error' )
      end
    end

    context "executing a nested dissociated block" do
      it "defers execution of the outer code block only" do
        (
          allow( em_system ).
            to receive( :defer ) do |block, callback|
              result = block.call
              callback.call result
            end
        ).once

        exec_result = nil
        subject.execute do |s|
          subject.exec_dissociated {
            exec_result = subject.exec_dissociated { :the_result }
          }
        end
        expect( exec_result ).to eq( :the_result )
      end

    end

    context "sleeping" do
      before do
        @run_sequence = []
        allow( em_system ).to receive( :add_timer ) do |delay_time, callback|
          @run_sequence << [:add_timer, delay_time]
          callback.call
        end
      end

      it "adds an EM timer, and resumes after the timer callback fires" do
        subject.execute do |s|
          s.sleep 5.5
          @run_sequence << :after_timer
        end

        expect( @run_sequence ).to eq( [
          [:add_timer, 5.5],
          :after_timer
        ] )
      end
    end

  end

end
