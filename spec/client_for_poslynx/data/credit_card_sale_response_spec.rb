require 'spec_helper'

module ClientForPoslynx

  describe Data::CreditCardSaleResponse do

    it "Serializes to a PLResponse XML document for a CCSALE command" do
      expected_xml = <<XML
<?xml version="1.0"?>
<PLResponse>
  <Command>CCSALE</Command>
</PLResponse>
XML

      expect( subject.xml_serialize ).to eq( expected_xml )
    end

    it "Serializes all assigned members to appropriate elements" do
      subject.result                  = 'the-result'
      subject.result_text             = 'the-result-text'
      subject.processor_authorization = 'the-authorization'
      subject.record_number           = 'the-record'
      subject.reference_data          = 'the-reference-data'
      subject.error_code              = 'the-error-code'
      subject.merchant_supplied_id    = 'the-transaction'
      subject.client_id               = 'the-client'
      subject.card_type               = 'the-card-type'
      subject.authorized_amount       = 'the-authorized-amount'
      subject.card_number_last_4      = 'the-card-last-4'
      subject.merchant_id             = 'the-merchant'
      subject.terminal_id             = 'the-terminal'
      subject.transaction_date        = 'the-date'
      subject.transaction_time        = 'the-time'

      expected_xml = <<XML
<?xml version="1.0"?>
<PLResponse>
  <Command>CCSALE</Command>
  <Result>the-result</Result>
  <ResultText>the-result-text</ResultText>
  <Authorization>the-authorization</Authorization>
  <RecNum>the-record</RecNum>
  <RefData>the-reference-data</RefData>
  <ErrorCode>the-error-code</ErrorCode>
  <Id>the-transaction</Id>
  <ClientId>the-client</ClientId>
  <CardType>the-card-type</CardType>
  <AuthAmt>the-authorized-amount</AuthAmt>
  <CardNumber>the-card-last-4</CardNumber>
  <MerchantId>the-merchant</MerchantId>
  <TerminalId>the-terminal</TerminalId>
  <TransactionDate>the-date</TransactionDate>
  <TransactionTime>the-time</TransactionTime>
</PLResponse>
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
<PLResponse>
  <Command>CCSALE</Command>
  <Result>OK</Result>
  <Result>Sure</Result>
</PLResponse>
XML
      expect {
        described_class.xml_deserialize xml_input
      }.to raise_exception( InvalidXmlContentError )
    end

    it "raises InvalidXmlContentError deserializing XML with missing Command element" do
      xml_input = <<XML
<PLResponse>
</PLResponse>
XML
      expect {
        described_class.xml_deserialize xml_input
      }.to raise_exception( InvalidXmlContentError )
    end

    it "raises InvalidXmlContentError deserializing XML with wrong Command value" do
      xml_input = <<XML
<PLResponse>
  <Command>DOSOMETHING</Command>
</PLResponse>
XML
      expect {
        described_class.xml_deserialize xml_input
      }.to raise_exception( InvalidXmlContentError )
    end

    it "parses minimally acceptable XML data" do
      xml_input = <<XML
<PLResponse>
  <Command>CCSALE</Command>
</PLResponse>
XML
      actual_instance = described_class.xml_deserialize xml_input
      expect( actual_instance.authorized_amount ).to be_nil
    end

    it "keeps a copy of the original XML in the deserialized instance" do
      xml_input = <<XML
<PLResponse>
  <Command>CCSALE</Command>
  <Result>OK</Result>
  <SomeOtherThing>Apple</SomeOtherThing>
</PLResponse>
XML
      actual_instance = described_class.xml_deserialize xml_input
      expect( actual_instance.source_data ).to eq( xml_input )
    end

    it "parses XML data with all property elements supplied" do
      xml_input = <<XML
<PLResponse>
  <Command>CCSALE</Command>
  <Result>the-result</Result>
  <ResultText>the-result-text</ResultText>
  <Authorization>the-authorization</Authorization>
  <RecNum>the-record</RecNum>
  <RefData>the-reference-data</RefData>
  <ErrorCode>the-error-code</ErrorCode>
  <Id>the-transaction</Id>
  <ClientId>the-client</ClientId>
  <CardType>the-card-type</CardType>
  <AuthAmt>the-authorized-amount</AuthAmt>
  <CardNumber>the-card-last-4</CardNumber>
  <MerchantId>the-merchant</MerchantId>
  <TerminalId>the-terminal</TerminalId>
  <TransactionDate>the-date</TransactionDate>
  <TransactionTime>the-time</TransactionTime>
</PLResponse>
XML
      actual_instance = described_class.xml_deserialize xml_input

      expect( actual_instance.result                  ).to eq( 'the-result'            )
      expect( actual_instance.result_text             ).to eq( 'the-result-text'       )
      expect( actual_instance.processor_authorization ).to eq( 'the-authorization'     )
      expect( actual_instance.record_number           ).to eq( 'the-record'            )
      expect( actual_instance.reference_data          ).to eq( 'the-reference-data'    )
      expect( actual_instance.error_code              ).to eq( 'the-error-code'        )
      expect( actual_instance.merchant_supplied_id    ).to eq( 'the-transaction'       )
      expect( actual_instance.client_id               ).to eq( 'the-client'            )
      expect( actual_instance.card_type               ).to eq( 'the-card-type'         )
      expect( actual_instance.authorized_amount       ).to eq( 'the-authorized-amount' )
      expect( actual_instance.card_number_last_4      ).to eq( 'the-card-last-4'       )
      expect( actual_instance.merchant_id             ).to eq( 'the-merchant'          )
      expect( actual_instance.terminal_id             ).to eq( 'the-terminal'          )
      expect( actual_instance.transaction_date        ).to eq( 'the-date'              )
      expect( actual_instance.transaction_time        ).to eq( 'the-time'              )
    end
  end

end
