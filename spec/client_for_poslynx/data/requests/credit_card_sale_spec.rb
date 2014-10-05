require 'spec_helper'

module ClientForPoslynx

  describe Data::Requests::CreditCardSale do

    it_behaves_like "a data object"

    it "Serializes to an XML document for a CCSALE request" do
      mac = Data::Requests::DEFAULT_CLIENT_MAC
      expected_xml =
        "<PLRequest><Command>CCSALE</Command><ClientMAC>#{mac}</ClientMAC></PLRequest>\n"

      expect( subject.xml_serialize ).to eq( expected_xml )
    end


    it "Serializes all assigned members to appropriate elements" do
      subject.client_mac           = 'the-MAC'
      subject.merchant_supplied_id = 'the-transaction'
      subject.client_id            = 'the-client'
      subject.tax_amount           = 'the-tax'
      subject.customer_code        = 'the-code'
      subject.amount               = 'the-amount'
      subject.input_source         = 'the-source'
      subject.track_1              = 'the-one'
      subject.track_2              = 'the-two'
      subject.card_number          = 'the-number'
      subject.expiry_date          = 'the-expiration'
      subject.capture_signature    = 'the-capture-signature'

      expected_xml =
        "<PLRequest>" +
          "<Command>CCSALE</Command>" +
          "<ClientMAC>the-MAC</ClientMAC>" +
          "<Id>the-transaction</Id>" +
          "<ClientId>the-client</ClientId>" +
          "<TaxAmount>the-tax</TaxAmount>" +
          "<CustomerCode>the-code</CustomerCode" +
          "><Amount>the-amount</Amount>" +
          "<Input>the-source</Input>" +
          "<Track2>the-two</Track2>" +
          "<Track1>the-one</Track1>" +
          "<CardNumber>the-number</CardNumber>" +
          "<ExpiryDate>the-expiration</ExpiryDate>" +
          "<ReqPPSigCapture>the-capture-signature</ReqPPSigCapture>" +
        "</PLRequest>\n"

      expect( subject.xml_serialize ).to eq( expected_xml )
    end


    it "parses minimally acceptable XML data" do
      xml_input = <<-XML
<PLRequest>
  <Command>CCSALE</Command>
</PLRequest>
      XML

      actual_instance = described_class.xml_deserialize xml_input
      expect( actual_instance.card_number ).to be_nil
    end


    it "parses XML data with all property elements supplied" do
      xml_input = <<-XML
<PLRequest>
  <Command>CCSALE</Command>
  <ClientMAC>the-MAC</ClientMAC>
  <Id>the-transaction</Id>
  <ClientId>the-client</ClientId>
  <TaxAmount>the-tax</TaxAmount>
  <CustomerCode>the-code</CustomerCode>
  <Amount>the-amount</Amount>
  <Input>the-source</Input>
  <Track2>the-two</Track2>
  <Track1>the-one</Track1>
  <CardNumber>the-number</CardNumber>
  <ExpiryDate>the-expiration</ExpiryDate>
  <ReqPPSigCapture>the-capture-signature</ReqPPSigCapture>
</PLRequest>
      XML

      actual_instance = described_class.xml_deserialize xml_input

      expect( actual_instance.client_mac           ).to eq( 'the-MAC'               )
      expect( actual_instance.merchant_supplied_id ).to eq( 'the-transaction'       )
      expect( actual_instance.client_id            ).to eq( 'the-client'            )
      expect( actual_instance.tax_amount           ).to eq( 'the-tax'               )
      expect( actual_instance.customer_code        ).to eq( 'the-code'              )
      expect( actual_instance.amount               ).to eq( 'the-amount'            )
      expect( actual_instance.input_source         ).to eq( 'the-source'            )
      expect( actual_instance.track_1              ).to eq( 'the-one'               )
      expect( actual_instance.track_2              ).to eq( 'the-two'               )
      expect( actual_instance.card_number          ).to eq( 'the-number'            )
      expect( actual_instance.expiry_date          ).to eq( 'the-expiration'        )
      expect( actual_instance.capture_signature    ).to eq( 'the-capture-signature' )
    end

    it "accepts a canonical visitor" do
      visitor = Object.new
      visitor.extend Data::Requests::CanVisit
      expect{ subject.accept_visitor visitor }.not_to raise_exception
    end

    it "sends itself to an accepted visitor" do
      visitor = double :visitor
      expect( visitor ).to receive( :visit_CreditCardSale ).with( subject )
      subject.accept_visitor visitor
    end

  end

end
