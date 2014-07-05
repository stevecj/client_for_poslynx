require 'spec_helper'

module ClientForPoslynx

  describe Data::CreditCardSaleRequest do

    it "Serializes to a PLRequest XML document for a CCSALE command" do
      expected_xml = <<XML
<?xml version="1.0"?>
<PLRequest>
  <Command>CCSALE</Command>
  <ClientMAC>#{Data::DEFAULT_CLIENT_MAC}</ClientMAC>
</PLRequest>
XML

      expect( subject.xml_serialize ).to eq( expected_xml )
    end

    it "Serializes all assigned members to appropriate elements" do
      subject.merchant_supplied_id        = 'the-transaction'
      subject.client_id                   = 'the-client'
      subject.client_mac                  = 'the-MAC'
      subject.tax_amount                  = 'the-tax'
      subject.customer_code               = 'the-code'
      subject.amount                      = 'the-amount'
      subject.input_source                = 'the-source'
      subject.track_1                     = 'the-one'
      subject.track_2                     = 'the-two'
      subject.card_number                 = 'the-number'
      subject.expiry_date                 = 'the-expiration'
      subject.address_verification_street = 'the-street'
      subject.address_verification_zip    = 'the-zipcode'
      subject.card_verification_number    = 'the-cvv'

      expected_xml = <<XML
<?xml version="1.0"?>
<PLRequest>
  <Command>CCSALE</Command>
  <Id>the-transaction</Id>
  <ClientId>the-client</ClientId>
  <ClientMAC>the-MAC</ClientMAC>
  <TaxAmount>the-tax</TaxAmount>
  <CustomerCode>the-code</CustomerCode>
  <Amount>the-amount</Amount>
  <Input>the-source</Input>
  <Track2>the-two</Track2>
  <Track1>the-one</Track1>
  <CardNumber>the-number</CardNumber>
  <ExpiryDate>the-expiration</ExpiryDate>
  <AVSStreet>the-street</AVSStreet>
  <AVSZip>the-zipcode</AVSZip>
  <CVV>the-cvv</CVV>
</PLRequest>
XML

      expect( subject.xml_serialize ).to eq( expected_xml )
    end

    it "raises InvalidXmlError deserializing invalid XML" do
      expect {
        described_class.xml_deserialize "I am not valid XML"
      }.to raise_exception( InvalidXmlError )
    end

    it "raises InvalidXmlContentError deserializing XML with wrong root" do
      xml_input = <<XML
<PLAppeal>
  <Command>CCSALE</Command>
</PLAppeal>
XML
      expect {
        described_class.xml_deserialize xml_input
      }.to raise_exception( InvalidXmlContentError )
    end

    it "raises InvalidXmlContentError deserializing XML with a repeated property element" do
      xml_input = <<XML
<PLRequest>
  <Command>CCSALE</Command>
  <Amount>1</Amount>
  <Amount>2</Amount>
</PLRequest>
XML
      expect {
        described_class.xml_deserialize xml_input
      }.to raise_exception( InvalidXmlContentError )
    end

    it "raises InvalidXmlContentError deserializing XML with missing Command element" do
      xml_input = <<XML
<PLRequest>
</PLRequest>
XML
      expect {
        described_class.xml_deserialize xml_input
      }.to raise_exception( InvalidXmlContentError )
    end

    it "raises InvalidXmlContentError deserializing XML with wrong Command value" do
      xml_input = <<XML
<PLRequest>
  <Command>DOSOMETHING</Command>
</PLRequest>
XML
      expect {
        described_class.xml_deserialize xml_input
      }.to raise_exception( InvalidXmlContentError )
    end

    it "raises InvalidXmlContentError deserializing XML with unrecognized property" do
      xml_input = <<XML
<PLRequest>
  <Command>CCSALE</Command>
  <Wazzat>abc</Wazzat>
</PLRequest>
XML
      expect {
        described_class.xml_deserialize xml_input
      }.to raise_exception( InvalidXmlContentError )
    end

    it "parses minimally acceptable XML data" do
      xml_input = <<XML
<PLRequest>
  <Command>CCSALE</Command>
</PLRequest>
XML
      actual_instance = described_class.xml_deserialize xml_input
      expect( actual_instance.card_number ).to be_nil
    end

    it "parses XML data with all property elements supplied" do
      xml_input = <<XML
<PLRequest>
  <Command>CCSALE</Command>
  <Id>the-transaction</Id>
  <ClientId>the-client</ClientId>
  <ClientMAC>the-MAC</ClientMAC>
  <TaxAmount>the-tax</TaxAmount>
  <CustomerCode>the-code</CustomerCode>
  <Amount>the-amount</Amount>
  <Input>the-source</Input>
  <Track2>the-two</Track2>
  <Track1>the-one</Track1>
  <CardNumber>the-number</CardNumber>
  <ExpiryDate>the-expiration</ExpiryDate>
  <AVSStreet>the-street</AVSStreet>
  <AVSZip>the-zipcode</AVSZip>
  <CVV>the-cvv</CVV>
</PLRequest>
XML
      actual_instance = described_class.xml_deserialize xml_input

      expect( actual_instance.merchant_supplied_id        ).to eq( 'the-transaction' )
      expect( actual_instance.client_id                   ).to eq( 'the-client'      )
      expect( actual_instance.client_mac                  ).to eq( 'the-MAC'         )
      expect( actual_instance.tax_amount                  ).to eq( 'the-tax'         )
      expect( actual_instance.customer_code               ).to eq( 'the-code'        )
      expect( actual_instance.amount                      ).to eq( 'the-amount'      )
      expect( actual_instance.input_source                ).to eq( 'the-source'      )
      expect( actual_instance.track_1                     ).to eq( 'the-one'         )
      expect( actual_instance.track_2                     ).to eq( 'the-two'         )
      expect( actual_instance.card_number                 ).to eq( 'the-number'      )
      expect( actual_instance.expiry_date                 ).to eq( 'the-expiration'  )
      expect( actual_instance.address_verification_street ).to eq( 'the-street'      )
      expect( actual_instance.address_verification_zip    ).to eq( 'the-zipcode'     )
      expect( actual_instance.card_verification_number    ).to eq( 'the-cvv'         )
    end
  end

end
