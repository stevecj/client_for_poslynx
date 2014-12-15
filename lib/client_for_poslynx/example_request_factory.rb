# coding: utf-8

module ClientForPoslynx

  # A class of factories for building request data instances that
  # are pre-populated with example data. This is primarily useful
  # for exploration and experimentation in the irb console.
  class ExampleRequestFactory
    attr_reader :client_mac

    # Initializes a ne factory instance, optionally with a
    # client_mac value to be assigned to each request-data object
    # that the factory builds.
    def initialize(client_mac = nil)
      @client_mac = client_mac
    end

    def pin_pad_initialize_request
      Data::Requests::PinPadInitialize.new.tap { |req|
        assign_common_example_request_attrs_to req
        req.idle_prompt = "Example idle prompt"
      }
    end

    def pin_pad_reset_request
      Data::Requests::PinPadReset.new.tap { |req|
        assign_common_example_request_attrs_to req
      }
    end

    def pin_pad_display_message_request
      ClientForPoslynx::Data::Requests::PinPadDisplayMessage.new.tap { |req|
        assign_common_example_request_attrs_to req
        req.text_lines = [
          "First example line",
          "Second example line",
        ]
        req.line_count = 2
        req.button_labels = [
          "1st of optional buttons",
          "2nd button",
        ]
      }
    end

    def credit_card_sale_request
      ClientForPoslynx::Data::Requests::CreditCardSale.new.tap { |req|
        assign_common_example_request_attrs_to req
        req.merchant_supplied_id = 'INVC-123-MERCH-SUPPL'
        req.amount               = '101.25'
        req.input_source         = 'EXTERNAL'
        req.capture_signature    = 'Yes'
      }
    end

    def debit_card_sale_request
      ClientForPoslynx::Data::Requests::DebitCardSale.new.tap { |req|
        assign_common_example_request_attrs_to req
        req.merchant_supplied_id = 'INVC-123-MERCH-SUPPL'
        req.amount               = '101.25'
        req.cash_back            =  '20.00'
        req.input_source         = 'EXTERNAL'
      }
    end

    def pin_pad_display_specified_form_request
      ClientForPoslynx::Data::Requests::PinPadDisplaySpecifiedForm.new.tap { |req|
        assign_common_example_request_attrs_to req
        req.form_name = 'my_special_form'
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

    def pin_pad_get_signature
      ClientForPoslynx::Data::Requests::PinPadGetSignature.new.tap { |req|
        assign_common_example_request_attrs_to req
      }
    end

    private

    def assign_common_example_request_attrs_to(request)
      request.client_mac = client_mac if client_mac
    end

  end

end
