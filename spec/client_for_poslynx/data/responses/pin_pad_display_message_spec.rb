require 'spec_helper'

module ClientForPoslynx

  describe Data::Responses::PinPadDisplayMessage do


    it "Serializes to a PLResponse XML document for a PPDISPLAY response" do
      expected_xml = "<PLResponse><Command>PPDISPLAY</Command></PLResponse>\n"
      expect( subject.xml_serialize ).to eq( expected_xml )
    end


    it "Serializes all assigned members to appropriate elements" do
      subject.result          = 'the-result'
      subject.result_text     = 'the-text'
      subject.error_code      = 'the-code'
      subject.button_response = 'the-response'

      expected_xml =
        "<PLResponse>" +
          "<Command>PPDISPLAY</Command>" +
          "<Result>the-result</Result>" +
          "<ResultText>the-text</ResultText>" +
          "<ErrorCode>the-code</ErrorCode>" +
          "<Response>the-response</Response>" +
        "</PLResponse>\n"

      expect( subject.xml_serialize ).to eq( expected_xml )
    end


    it "raises InvalidXmlContentError deserializing XML with missing Command element" do
      xml_input = <<-XML
<PLResponse>
</PLResponse>
      XML
      expect {
        described_class.xml_deserialize xml_input
      }.to raise_exception( InvalidXmlContentError )
    end


    it "raises InvalidXmlContentError deserializing XML with wrong Command value" do
      xml_input = <<-XML
<PLResponse>
  <Command>DOSOMETHING</Command>
</PLResponse>
      XML

      expect {
        described_class.xml_deserialize xml_input
      }.to raise_exception( InvalidXmlContentError )
    end


    it "parses minimally acceptable XML data" do
      xml_input = <<-XML
<PLResponse>
  <Command>PPDISPLAY</Command>
</PLResponse>
      XML

      actual_instance = described_class.xml_deserialize xml_input
      expect( actual_instance.result ).to be_nil
    end


    it "parses XML data with all property elements supplied" do
      xml_input = <<-XML
<PLResponse>
  <Command>PPDISPLAY</Command>
  <Result>the-result</Result>
  <ResultText>the-text</ResultText>
  <ErrorCode>the-code</ErrorCode>
  <Response>the-response</Response>
</PLResponse>
      XML

      actual_instance = described_class.xml_deserialize xml_input

      expect( actual_instance.result          ).to eq( 'the-result'   )
      expect( actual_instance.result_text     ).to eq( 'the-text'     )
      expect( actual_instance.error_code      ).to eq( 'the-code'     )
      expect( actual_instance.button_response ).to eq( 'the-response' )
    end


  end

end
