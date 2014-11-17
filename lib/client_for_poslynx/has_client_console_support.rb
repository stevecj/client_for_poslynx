#!/usr/bin/env ruby

require 'client_for_poslynx'
require_relative 'has_client_console_support/connection'
require_relative 'has_client_console_support/response_ready_monitor'

module ClientForPoslynx

  module HasClientConsoleSupport

    def poslynx_client
      @@poslynx_client ||= Client.new
    end

    class Client
      def config
        @config ||= Config.new
      end

      def send_request(request)
        conn = Connection.connect( config )
        conn.puts request.xml_serialize
        ready = ResponseReadyMonitor.ready?( conn )
        response = get_response_from( conn.io ) if ready
        conn.close
        response
      end

      def example_pin_pad_initialize_request
        ClientForPoslynx::Data::Requests::PinPadInitialize.new.tap { |req|
          assign_common_example_request_attrs_to req
          req.idle_prompt = "Example idle prompt"
        }
      end

      def example_pin_pad_display_message_request
        ClientForPoslynx::Data::Requests::PinPadDisplayMessage.new.tap { |req|
          assign_common_example_request_attrs_to req
          req.text_lines = [
            "First example line",
            "Second example line",
          ]
          req.line_count = 2
          req.button_labels = [
            "1st of optional buttons",
            "2nd button"
          ]
        }
      end

      def example_credit_card_sale_request
        ClientForPoslynx::Data::Requests::CreditCardSale.new.tap { |req|
          assign_common_example_request_attrs_to req
          req.merchant_supplied_id = 'INVC-123-MERCH-SUPPL'
          req.amount               = '101.25'
          req.input_source         = 'EXTERNAL'
          req.capture_signature    = 'Yes'
        }
      end

      def example_debit_card_sale_request
        ClientForPoslynx::Data::Requests::DebitCardSale.new.tap { |req|
          assign_common_example_request_attrs_to req
          req.merchant_supplied_id = 'INVC-123-MERCH-SUPPL'
          req.amount               = '101.25'
          req.cash_back            =  '20.00'
          req.input_source         = 'EXTERNAL'
        }
      end

      def example_pin_pad_display_specified_form_request
        ClientForPoslynx::Data::Requests::PinPadDisplaySpecifiedForm.new.tap { |req|
          assign_common_example_request_attrs_to req
          req.text_values = [
            "First example text value",
            "Second example text value",
          ]
          req.button_labels = [
            "1st of optional buttons",
            "2nd button"
          ]
        }
      end

      def example_pin_pad_get_signature
        ClientForPoslynx::Data::Requests::PinPadGetSignature.new.tap { |req|
          assign_common_example_request_attrs_to req
        }
      end

      private

      def get_response_from( connection )
        reader = MessageHandling.stream_data_reader( connection )
        reader.get_data
      end

      def assign_common_example_request_attrs_to(request)
        request.client_mac = config.client_mac_for_examples if config.client_mac_for_examples
      end

    end

    class Config
      attr_accessor :host, :port, :use_ssl, :client_mac_for_examples
    end

  end
end
