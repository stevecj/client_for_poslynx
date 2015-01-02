require 'spec_helper'

module ClientForPoslynx

  describe Data::Requests::DebitCardSale do

    it_behaves_like "a request data object"

    it "Serializes to an XML document for a DCSALE request" do
      mac = Data::Requests::DEFAULT_CLIENT_MAC
      expected_xml =
        "<PLRequest><Command>DCSALE</Command><ClientMAC>#{mac}</ClientMAC></PLRequest>\n"

      expect( subject.xml_serialize ).to eq( expected_xml )
    end


    it "Serializes all assigned members to appropriate elements" do
      subject.client_mac           = 'the-MAC'
      subject.merchant_supplied_id = 'the-transaction'
      subject.client_id            = 'the-client'
      subject.amount               = 'the-amount'
      subject.input_source         = 'the-source'
      subject.track_1              = 'the-one'
      subject.track_2              = 'the-two'
      subject.card_number          = 'the-number'
      subject.expiry_date          = 'the-expiration'
      subject.cash_back            = 'the-cash-back'

      expected_xml =
        "<PLRequest>" +
          "<Command>DCSALE</Command>" +
          "<ClientMAC>the-MAC</ClientMAC>" +
          "<Id>the-transaction</Id>" +
          "<ClientId>the-client</ClientId>" +
          "<Amount>the-amount</Amount>" +
          "<Input>the-source</Input>" +
          "<Track2>the-two</Track2>" +
          "<Track1>the-one</Track1>" +
          "<CardNumber>the-number</CardNumber>" +
          "<ExpiryDate>the-expiration</ExpiryDate>" +
          "<Cashback>the-cash-back</Cashback>" +
        "</PLRequest>\n"

      expect( subject.xml_serialize ).to eq( expected_xml )
    end


    it "parses minimally acceptable XML data" do
      xml_input = <<-XML
<PLRequest>
  <Command>DCSALE</Command>
</PLRequest>
      XML

      actual_instance = described_class.xml_deserialize xml_input
      expect( actual_instance.card_number ).to be_nil
    end


    it "parses XML data with all property elements supplied" do
      xml_input = <<-XML
<PLRequest>
  <Command>DCSALE</Command>
  <ClientMAC>the-MAC</ClientMAC>
  <Id>the-transaction</Id>
  <ClientId>the-client</ClientId>
  <Amount>the-amount</Amount>
  <CustomerCode>the-code</CustomerCode>
  <Input>the-source</Input>
  <Track2>the-two</Track2>
  <Track1>the-one</Track1>
  <CardNumber>the-number</CardNumber>
  <ExpiryDate>the-expiration</ExpiryDate>
  <Cashback>the-cash-back</Cashback>
</PLRequest>
      XML

      actual_instance = described_class.xml_deserialize xml_input

      expect( actual_instance.client_mac           ).to eq( 'the-MAC'         )
      expect( actual_instance.merchant_supplied_id ).to eq( 'the-transaction' )
      expect( actual_instance.client_id            ).to eq( 'the-client'      )
      expect( actual_instance.amount               ).to eq( 'the-amount'      )
      expect( actual_instance.input_source         ).to eq( 'the-source'      )
      expect( actual_instance.track_1              ).to eq( 'the-one'         )
      expect( actual_instance.track_2              ).to eq( 'the-two'         )
      expect( actual_instance.card_number          ).to eq( 'the-number'      )
      expect( actual_instance.expiry_date          ).to eq( 'the-expiration'  )
      expect( actual_instance.cash_back            ).to eq( 'the-cash-back'   )
    end

    it "accepts a canonical visitor" do
      visitor = Object.new
      visitor.extend Data::Requests::CanVisit
      expect{ subject.accept_visitor visitor }.not_to raise_exception
    end

    it "sends itself to an accepted visitor" do
      visitor = double :visitor
      expect( visitor ).to receive( :visit_DebitCardSale ).with( subject )
      subject.accept_visitor visitor
    end

  end

end
