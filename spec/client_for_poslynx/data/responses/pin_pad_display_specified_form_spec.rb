require 'spec_helper'

module ClientForPoslynx

  describe Data::Responses::PinPadDisplaySpecifiedForm do

    it_behaves_like "a response data object"

    it "Serializes to a PLResponse XML document for a PPSPECIFIEDFORM response" do
      expected_xml = "<PLResponse><Command>PPSPECIFIEDFORM</Command></PLResponse>\n"
      expect( subject.xml_serialize ).to eq( expected_xml )
    end


    it "Serializes all assigned members to appropriate elements" do
      subject.result          = 'the-result'
      subject.result_text     = 'the-text'
      subject.error_code      = 'the-code'
      subject.button_response = 'the-response'
      subject.signature_data  = 'the-signature-data'

      expected_xml =
        "<PLResponse>" +
          "<Command>PPSPECIFIEDFORM</Command>" +
          "<Result>the-result</Result>" +
          "<ResultText>the-text</ResultText>" +
          "<ErrorCode>the-code</ErrorCode>" +
          "<Response>the-response</Response>" +
          "<Signature>the-signature-data</Signature>" +
        "</PLResponse>\n"

      expect( subject.xml_serialize ).to eq( expected_xml )
    end


    it "parses minimally acceptable XML data" do
      xml_input = <<-XML
<PLResponse>
  <Command>PPSPECIFIEDFORM</Command>
</PLResponse>
      XML

      actual_instance = described_class.xml_deserialize xml_input
      expect( actual_instance.result ).to be_nil
    end


    it "parses XML data with all property elements supplied" do
      xml_input = <<-XML
<PLResponse>
  <Command>PPSPECIFIEDFORM</Command>
  <Result>the-result</Result>
  <ResultText>the-text</ResultText>
  <ErrorCode>the-code</ErrorCode>
  <Response>the-response</Response>
  <Signature>the-signature-data</Signature>
</PLResponse>
      XML

      actual_instance = described_class.xml_deserialize xml_input

      expect( actual_instance.result          ).to eq( 'the-result'         )
      expect( actual_instance.result_text     ).to eq( 'the-text'           )
      expect( actual_instance.error_code      ).to eq( 'the-code'           )
      expect( actual_instance.button_response ).to eq( 'the-response'       )
      expect( actual_instance.signature_data  ).to eq( 'the-signature-data' )
    end


  end

end
