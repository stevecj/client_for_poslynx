require 'spec_helper'

module ClientForPoslynx

  describe Data::Responses::AbstractResponse do

    it "Serializes to a response document" do
      expected_xml = "<PLResponse/>\n"

      expect( subject.xml_serialize ).to eq( expected_xml )
    end

    it "Serializes all assigned members to appropriate elements" do
      subject.result                  = 'the-result'
      subject.result_text             = 'the-result-text'
      subject.error_code              = 'the-error-code'

      expected_xml =
        "<PLResponse>" +
          "<Result>the-result</Result>" +
          "<ResultText>the-result-text</ResultText>" +
          "<ErrorCode>the-error-code</ErrorCode>" +
        "</PLResponse>\n"

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
</PLAppeal>
XML
      expect {
        described_class.xml_deserialize xml_input
      }.to raise_exception( InvalidXmlContentError )
    end

    it "raises InvalidXmlContentError deserializing XML with a repeated property element" do
      xml_input = <<XML
<PLResponse>
  <Result>OK</Result>
  <Result>Sure</Result>
</PLResponse>
XML
      expect {
        described_class.xml_deserialize xml_input
      }.to raise_exception( InvalidXmlContentError )
    end

    it "parses minimally acceptable XML data" do
      xml_input = <<XML
<PLResponse>
</PLResponse>
XML
      actual_instance = described_class.xml_deserialize xml_input
      expect( actual_instance.result ).to be_nil
    end

    it "keeps a copy of the original XML in the deserialized instance" do
      xml_input = <<XML
<PLResponse>
  <Result>OK</Result>
  <SomeOtherThing>Apple</SomeOtherThing>
</PLResponse>
XML
      actual_instance = described_class.xml_deserialize xml_input
      expect( actual_instance.source_data ).to eq( xml_input )
    end

  end

end
