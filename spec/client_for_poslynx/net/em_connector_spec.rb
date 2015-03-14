# coding: utf-8

require 'spec_helper'

module ClientForPoslynx

  describe Net::EM_Connector do
    describe "default initialization" do
      subject { described_class.new( :the_server, :the_port ) }

      it "Has ::EM as its em_system" do
        expect( subject.em_system ).to eq( ::EM )
      end

      it "Has Net::EM_Connector::ConnectionHandler as its connection_handler" do
        expect( subject.handler_class ).to eq( Net::EM_Connector::ConnectionHandler )
      end

      it "Sets the connection status to :initial" do
        expect( subject.connection_status ).to eq( :initial )
      end
    end

    context "actions and events" do
      subject { described_class.new(
        :the_server, :the_port,
        em_system: em_system,
        handler: handler_class
      ) }

      let( :em_system ) { double( :em_system ) }
      let( :handler_class ) { Class.new do
        include Net::EM_Connector::HandlesConnection
      end }

      describe '#connect' do
        before do
          @handler_instance = nil
          allow( em_system ).to receive( :connect ) do |server, port, handler, *handler_args|
            @handler_instance = handler.new( *handler_args )
            nil
          end
        end

        let( :on_success ) { double(:on_success, call: nil) }
        let( :on_failure ) { double(:on_failure, call: nil) }

        context "initial connection" do
          before do
            subject.connect on_success: on_success, on_failure: on_failure
          end

          it "tries to open an EM connection using the connector's handler class" do
            expect( em_system ).to have_received( :connect ) do |server, port, handler, *handler_args|
              expect( server ).to eq( :the_server )
              expect( port ).to eq( :the_port )
              expect( handler ).to eq( handler_class )
            end
          end

          it "exposes the handler instance" do
            expect( subject.connection ).to eq( @handler_instance )
          end

          it "sets the connection status to :connecting" do
            expect( subject.connection_status ).to eq( :connecting )
          end

          context "when connection is completed" do
            before do
              @handler_instance.connection_completed
            end

            it "reports success and not failure" do
              expect( on_success ).to     have_received( :call )
              expect( on_failure ).not_to have_received( :call )
            end

            it "sets the connection status to :connected" do
              expect( subject.connection_status ).to eq( :connected )
            end
          end

          context "when the connection attempt fails" do
            before do
              @handler_instance.unbind
            end

            it "reports failure and not success" do
              expect( on_failure ).to     have_received(:call)
              expect( on_success ).not_to have_received(:call)
            end

            it "sets the connection status to :disconnected" do
              expect( subject.connection_status ).to eq( :disconnected )
            end
          end

          context "following successful connection" do
            before do
              @handler_instance.connection_completed
            end

            it "does not report failure later when subsequently disconnected" do
              @handler_instance.unbind
              expect( on_failure ).not_to have_received(:call)
            end
          end
        end

        context "when previously connected" do
          before do
            # Establish previous connection.
            subject.connect
            @handler_instance.connection_completed
          end

          context "when currently connected" do
            before do
              subject.connect on_success: on_success, on_failure: on_failure
            end

            it "reports success and not failure" do
              expect( on_success ).to     have_received( :call )
              expect( on_failure ).not_to have_received( :call )
            end
          end

          context "when not currently connected" do
            before do
              @handler_instance.unbind
              allow( @handler_instance ).to receive( :reconnect )

              subject.connect on_success: on_success, on_failure: on_failure
              expect( on_success ).not_to have_received( :call )  # Sanity check.
            end

            it "reconnects" do
              expect( @handler_instance ).to have_received( :reconnect ).with( :the_server, :the_port )
            end

            it "reports success and not failure when connected" do
              @handler_instance.connection_completed
              expect( on_success ).to     have_received( :call )
              expect( on_failure ).not_to have_received( :call )
            end

            it "reports failure and not success when unbound" do
              @handler_instance.unbind
              expect( on_failure ).to     have_received( :call )
              expect( on_success ).not_to have_received( :call )
            end
          end
        end

        context "when a pending connection is in progress" do
          before do
            # Initiate previously pending connection.
            subject.connect(
              on_success: on_success_of_pending,
              on_failure: on_failure_of_pending,
            )

            subject.connect on_success: on_success, on_failure: on_failure
          end

          let( :on_success_of_pending ) { double(:on_success_of_pending, call: nil) }
          let( :on_failure_of_pending ) { double(:on_failure_of_pending, call: nil) }

          it "does not issue its own separate EM connection request" do
            expect( em_system ).to have_received( :connect ).once
          end

          context "when connection is completed" do
            before do
              @handler_instance.connection_completed
            end

            it "reports success for previously pending request" do
              expect( on_success_of_pending ).to have_received( :call )
            end

            it "reports success for current request" do
              expect( on_success ).to have_received( :call )
            end
          end

          context "when the connection attempt fails" do
            before do
              @handler_instance.unbind
            end

            it "reports failure for previously pending request" do
              expect( on_failure_of_pending ).to have_received( :call )
            end

            it "reports failure for current request" do
              expect( on_failure ).to have_received( :call )
            end
          end

        end

      end

      context "when an open connection is lost or remotely disconnected" do
        before do
          @handler_instance = nil
          allow( em_system ).to receive( :connect ) do |server, port, handler, *handler_args|
            @handler_instance = handler.new( *handler_args )
            nil
          end
          subject.connect
          @handler_instance.connection_completed
          @handler_instance.unbind
        end

        it "sets the connection status to :disconnected" do
          expect( subject.connection_status ).to eq( :disconnected )
        end
      end

      describe '#disconnect' do
        let( :on_completed ) { double(:on_completed, call: nil) }

        context "when has never been connected" do
          before do
            subject.disconnect on_completed: on_completed
          end

          it "reports completion" do
            expect( on_completed ).to have_received( :call )
          end

          it "leaves connection status as :initial" do
            expect( subject.connection_status ).to eq( :initial )
          end
        end

        context "when previously connected" do
          before do
            @handler_instance = nil
            allow( em_system ).to receive( :connect ) do |server, port, handler, *handler_args|
              @handler_instance = handler.new( *handler_args )
              nil
            end
            subject.connect
            @handler_instance.connection_completed
          end

          context "when not currently connected" do
            before do
              @handler_instance.unbind
              subject.disconnect on_completed: on_completed
            end

            it "reports completion" do
              expect( on_completed ).to have_received( :call )
            end

            it "leaves the connection status as :disconnected" do
              expect( subject.connection_status ).to eq( :disconnected )
            end
          end

          context "when currently connected" do
            before do
              allow( @handler_instance ).to receive( :close_connection )
              subject.disconnect on_completed: on_completed
            end

            it "closes the open connection" do
              expect( @handler_instance ).to have_received( :close_connection )
            end

            it "sets the connection status to :disconnecting" do
              expect( subject.connection_status ).to eq( :disconnecting )
            end

            context "when done disconnecting" do
              it "reports completion" do
                expect( on_completed ).not_to have_received( :call )  # Sanity check.
                @handler_instance.unbind
                expect( on_completed ).to have_received( :call )
              end

              it "sets the connection status to :disconnected" do
                @handler_instance.unbind
                expect( subject.connection_status ).to eq( :disconnected )
              end
            end
          end

        end
      end

      describe '#send_request' do
        let( :opts_for_send_request ) {
          { on_response: on_response, on_failure: on_failure }
        }
        let( :on_response ) { double(:on_response, call: nil) }
        let( :on_failure  ) { double(:on_failure , call: nil) }

        context "while not connected" do
          it "reports failure" do
            subject.send_request :the_request_data, opts_for_send_request
            expect( on_failure ).to have_received( :call )
          end
        end

        context "while connected" do
          before do
            @handler_instance = nil
            allow( em_system ).to receive( :connect ) do |server, port, handler, *handler_args|
              @handler_instance = handler.new( *handler_args )
              nil
            end
            subject.connect
            @handler_instance.connection_completed
            allow( @handler_instance ).to receive( :send_request )
            subject.send_request :the_request_data, opts_for_send_request
          end

          it "sends a request to the POSLynx" do
            expect( @handler_instance ).to have_received( :send_request ).with( :the_request_data  )
          end

          it "records the pending request state" do
            expect( subject.latest_request ).to eq( [:the_request_data, opts_for_send_request] )
            expect( subject.status_of_request ).to eq( :pending )
          end

          context "when a response is received" do
            before do
              @handler_instance.receive_response :the_response_data
            end

            it "records the got-response request state" do
              expect( subject.status_of_request ).to eq( :got_response )
            end

            it "reports the response data" do
              expect( on_response ).to have_received( :call ).with( :the_response_data )
            end
          end

          context "when connection is lost w/o response" do
            before do
              @handler_instance.unbind
            end

            it "records the failed request state" do
              expect( subject.status_of_request ).to eq( :failed )
            end

            it "reports failure" do
              expect( on_failure ).to have_received( :call )
            end
          end

        end
      end

      describe '#get_response' do
        let( :opts_for_get_response ) {
          { on_response: on_response, on_failure: on_failure }
        }
        let( :on_response ) { double(:on_response, call: nil) }
        let( :on_failure  ) { double(:on_failure , call: nil) }

        context "while not connected" do
          it "reports failure" do
            subject.get_response opts_for_get_response
            expect( on_failure ).to have_received( :call )
          end
        end

        context "while connected" do
          before do
            @handler_instance = nil
            allow( em_system ).to receive( :connect ) do |server, port, handler, *handler_args|
              @handler_instance = handler.new( *handler_args )
              nil
            end
            subject.connect
            @handler_instance.connection_completed
          end

          context "when no request has been previously sent" do
            it "reports failure" do
              subject.get_response opts_for_get_response
              expect( on_failure ).to have_received( :call )
            end
          end

          context "when a previous request is still pending" do
            before do
              allow( @handler_instance ).to receive( :send_request )
              subject.send_request :prev_request_data, some_prev_option: :some_prev_value
            end

            it "replaces the previous request options" do
              subject.get_response opts_for_get_response
              expect( subject.latest_request ).to eq( [
                :prev_request_data, opts_for_get_response
              ] )
            end

            context "when a response is received" do
              before do
                subject.get_response opts_for_get_response
                @handler_instance.receive_response :the_response_data
              end

              it "records the got-response request state" do
                expect( subject.status_of_request ).to eq( :got_response )
              end

              it "reports the response data" do
                expect( on_response ).to have_received( :call ).with( :the_response_data )
              end
            end

            context "when connection is lost w/o response" do
              before do
                subject.get_response opts_for_get_response
                @handler_instance.unbind
              end

              it "records the failed request state" do
                expect( subject.status_of_request ).to eq( :failed )
              end

              it "reports failure" do
                expect( on_failure ).to have_received( :call )
              end
            end
          end

          context "when the previous request failed, there is an open connection" do
            before do
              allow( @handler_instance ).to receive( :send_request )
              subject.send_request :prev_request_data
              @handler_instance.unbind
              @handler_instance.connection_completed
            end

            it "reports failure" do
              subject.get_response opts_for_get_response
              expect( on_failure ).to have_received( :call )
            end
          end

          context "when the previous request has completed" do
            before do
              allow( @handler_instance ).to receive( :send_request )
              subject.send_request :prev_request_data, some_prev_option: :some_prev_value
              @handler_instance.receive_response :the_previous_response
            end

            it "replaces the previous request options" do
              subject.get_response opts_for_get_response
              expect( subject.latest_request ).to eq( [
                :prev_request_data, opts_for_get_response
              ] )
            end

            it "reverts to a request status of pending" do
              subject.get_response opts_for_get_response
              expect( subject.status_of_request ).to eq( :pending )
            end

            context "when a response is received" do
              before do
                subject.get_response opts_for_get_response
                @handler_instance.receive_response :the_response_data
              end

              it "records the got-response request state" do
                expect( subject.status_of_request ).to eq( :got_response )
              end

              it "reports the response data" do
                expect( on_response ).to have_received( :call ).with( :the_response_data )
              end
            end

            context "when connection is lost w/o response" do
              before do
                subject.get_response opts_for_get_response
                @handler_instance.unbind
              end

              it "records the failed request state" do
                expect( subject.status_of_request ).to eq( :failed )
              end

              it "reports failure" do
                expect( on_failure ).to have_received( :call )
              end
            end
          end

        end
      end

    end
  end

end
