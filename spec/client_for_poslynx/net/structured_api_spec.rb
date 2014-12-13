# coding: utf-8

require 'spec_helper'
require 'stringio'

module ClientForPoslynx

  describe "Structured API" do

    it "makes and closes a connection" do
      client_action = ->(port, lq) do
        lq << :client_connecting
        client = Net::StructuredClient.new( '127.0.0.1', port )
        begin
          sleep 0.1  # Let server report connection acceptance.
          lq << :client_disconnecting
        ensure
          client.end_session
        end
      end

      server_action = ->(conn, lq) do
        lq << :server_received_connection
        conn.wait_writable
        c = conn.getc
        lq << if c.nil? then :server_received_eof else :server_didnt_receive_eof end
      end

      log_array = TestTCP_Server.run_client_server_session(
        client_action, server_action
      )

      expect( log_array ).to eq( [
        :client_connecting,
        :server_received_connection,
        :client_disconnecting,
        :server_received_eof,
      ] )
    end

    it "sends a request" do
      request_to_send = Data::Requests::PinPadDisplayMessage.new.tap do |req|
        req.client_mac = 'abc'
      end

      client_action = ->(port, lq) do
        client = Net::StructuredClient.new( '127.0.0.1', port )
        begin
          sleep 0.1  # Let server report connection acceptance.
          lq << :sending_request
          client.send_request request_to_send
        ensure
          client.end_session
        end
      end

      server_action = ->(conn, lq) do
        conn.wait_readable
        line = conn.gets
        lq << [ :server_received_line, line ]
      end

      log_array = TestTCP_Server.run_client_server_session(
        client_action, server_action
      )

      expect( log_array.length ).to eq( 2 )

      expect( log_array.first ).to eq( :sending_request )

      msg, serial_data = log_array.last
      expect( msg  ).to eq( :server_received_line )

      data = Data::AbstractData.xml_parse( serial_data )
      expect( data ).to be_kind_of( Data::Requests::PinPadDisplayMessage )
      expect( data.client_mac ).to eq( 'abc' )
    end

    it "receives a response" do
      response_data_to_send = Data::Responses::PinPadDisplayMessage.new.tap do |req|
        req.result = 'OkeyDokey'
      end
      serial_response_data_to_send = response_data_to_send.xml_serialize

      client_action = ->(port, lq) do
        client = Net::StructuredClient.new( '127.0.0.1', port )
        begin
          sleep 0.1  # Let server send response.
          lq << [ :got_response, client.got_response ]
        ensure
          client.end_session
        end
      end

      server_action = ->(conn, lq) do
        conn.wait_writable
        lq << :server_sending_response
        conn.puts serial_response_data_to_send
      end

      log_array = TestTCP_Server.run_client_server_session(
        client_action, server_action
      )

      expect( log_array.length ).to eq( 2 )

      expect( log_array.first ).to eq( :server_sending_response )

      msg, data = log_array.last
      expect( msg  ).to eq( :got_response )

      expect( data ).to be_kind_of( Data::Responses::PinPadDisplayMessage )
      expect( data.result ).to eq( 'OkeyDokey' )
    end

  end

end
