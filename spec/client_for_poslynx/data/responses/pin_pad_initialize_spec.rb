require 'spec_helper'

module ClientForPoslynx

  describe Data::Responses::PinPadInitialize do


    it "Serializes to a PLResponse XML document for a PPINIT response" do
      expected_xml = <<-XML
<?xml version="1.0"?>
<#{Data::Responses::ROOT_ELEMENT_NAME}>
  <Command>PPINIT</Command>
</#{Data::Responses::ROOT_ELEMENT_NAME}>
      XML

      expect( subject.xml_serialize ).to eq( expected_xml )
    end


    it "Serializes all assigned members to appropriate elements" do
      subject.result = 'the-result'
      subject.result_text = 'the-text'
      subject.error_code = 'the-code'

      expected_xml = <<-XML
<?xml version="1.0"?>
<#{Data::Responses::ROOT_ELEMENT_NAME}>
  <Command>PPINIT</Command>
  <Result>the-result</Result>
  <ResultText>the-text</ResultText>
  <ErrorCode>the-code</ErrorCode>
</#{Data::Responses::ROOT_ELEMENT_NAME}>
      XML

      expect( subject.xml_serialize ).to eq( expected_xml )
    end


    it "raises InvalidXmlContentError deserializing XML with missing Command element" do
      xml_input = <<-XML
<#{Data::Responses::ROOT_ELEMENT_NAME}>
</#{Data::Responses::ROOT_ELEMENT_NAME}>
      XML
      expect {
        described_class.xml_deserialize xml_input
      }.to raise_exception( InvalidXmlContentError )
    end


    it "raises InvalidXmlContentError deserializing XML with wrong Command value" do
      xml_input = <<-XML
<#{Data::Responses::ROOT_ELEMENT_NAME}>
  <Command>DOSOMETHING</Command>
</#{Data::Responses::ROOT_ELEMENT_NAME}>
      XML

      expect {
        described_class.xml_deserialize xml_input
      }.to raise_exception( InvalidXmlContentError )
    end


    it "parses minimally acceptable XML data" do
      xml_input = <<-XML
<#{Data::Responses::ROOT_ELEMENT_NAME}>
  <Command>PPINIT</Command>
</#{Data::Responses::ROOT_ELEMENT_NAME}>
      XML

      actual_instance = described_class.xml_deserialize xml_input
      expect( actual_instance.result ).to be_nil
    end


    it "parses XML data with all property elements supplied" do
      xml_input = <<-XML
<#{Data::Responses::ROOT_ELEMENT_NAME}>
  <Command>PPINIT</Command>
  <Result>the-result</Result>
  <ResultText>the-text</ResultText>
  <ErrorCode>the-code</ErrorCode>
</#{Data::Responses::ROOT_ELEMENT_NAME}>
      XML

      actual_instance = described_class.xml_deserialize xml_input

      expect( actual_instance.result      ).to eq( 'the-result' )
      expect( actual_instance.result_text ).to eq( 'the-text'   )
      expect( actual_instance.error_code  ).to eq( 'the-code'   )
    end


  end

end
