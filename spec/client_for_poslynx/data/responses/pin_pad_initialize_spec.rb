require 'spec_helper'

module ClientForPoslynx

  describe Data::Responses::PinPadInitialize do

    it "Serializes to a PLResponse XML document for a PPINIT response" do
      expected_xml = <<XML
<?xml version="1.0"?>
<PLResponse>
  <Command>PPINIT</Command>
</PLResponse>
XML

      expect( subject.xml_serialize ).to eq( expected_xml )
    end

    it "Serializes all assigned members to appropriate elements" do
      subject.result = 'the-result'
      subject.result_text = 'the-text'
      subject.error_code = 'the-code'

      expected_xml = <<XML
<?xml version="1.0"?>
<PLResponse>
  <Command>PPINIT</Command>
  <Result>the-result</Result>
  <ResultText>the-text</ResultText>
  <ErrorCode>the-code</ErrorCode>
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
  <Command>PPINIT</Command>
</PLAppeal>
XML
      expect {
        described_class.xml_deserialize xml_input
      }.to raise_exception( InvalidXmlContentError )
    end

    it "raises InvalidXmlContentError deserializing XML with a repeated property element" do
      xml_input = <<XML
<PLResponse>
  <Command>PPINIT</Command>
  <Response>1</Response>
  <Response>2</Response>
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
  <Command>PPINIT</Command>
</PLResponse>
XML
      actual_instance = described_class.xml_deserialize xml_input
      expect( actual_instance.result ).to be_nil
    end

    it "keeps a copy of the original XML in the deserialized instance" do
      xml_input = <<XML
<PLResponse>
  <Command>PPINIT</Command>
  <SomeOtherThing>Apple</SomeOtherThing>
</PLResponse>
XML
      actual_instance = described_class.xml_deserialize xml_input
      expect( actual_instance.source_data ).to eq( xml_input )
    end

    it "parses XML data with all property elements supplied" do
      xml_input = <<XML
<PLResponse>
  <Command>PPINIT</Command>
  <Result>the-result</Result>
  <ResultText>the-text</ResultText>
  <ErrorCode>the-code</ErrorCode>
</PLResponse>
XML
      actual_instance = described_class.xml_deserialize xml_input

      expect( actual_instance.result      ).to eq( 'the-result' )
      expect( actual_instance.result_text ).to eq( 'the-text'   )
      expect( actual_instance.error_code  ).to eq( 'the-code'   )
    end

  end

end
