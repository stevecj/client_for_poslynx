require 'spec_helper'

module ClientForPoslynx

  describe Data::Requests::AbstractRequest do

    it "Serializes to a request document" do
      mac = Data::Requests::DEFAULT_CLIENT_MAC
      expected_xml =
        "<PLRequest><ClientMAC>#{mac}</ClientMAC></PLRequest>\n"

      expect( subject.xml_serialize ).to eq( expected_xml )
    end

    it "Serializes all assigned members to appropriate elements" do
      subject.client_mac = 'the-MAC'

      expected_xml =
        "<PLRequest><ClientMAC>the-MAC</ClientMAC></PLRequest>\n"

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
<PLRequest>
  <ClientMAC>1</ClientMAC>
  <ClientMAC>2</ClientMAC>
</PLRequest>
XML
      expect {
        described_class.xml_deserialize xml_input
      }.to raise_exception( InvalidXmlContentError )
    end

    it "parses minimally acceptable XML data" do
      xml_input = <<XML
<PLRequest>
</PLRequest>
XML
      actual_instance = described_class.xml_deserialize xml_input
      expect( actual_instance.client_mac ).to be_nil
    end

    it "keeps a copy of the original XML in the deserialized instance" do
      xml_input = <<XML
<PLRequest>
  <SomeOtherThing>Apple</SomeOtherThing>
</PLRequest>
XML
      actual_instance = described_class.xml_deserialize xml_input
      expect( actual_instance.source_data ).to eq( xml_input )
    end
  end

end
