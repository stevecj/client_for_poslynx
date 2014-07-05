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
  end

end
