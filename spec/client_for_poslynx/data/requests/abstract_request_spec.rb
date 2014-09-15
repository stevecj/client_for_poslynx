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

    it "is duplicatable" do
      original_inst = described_class.new
      original_inst.client_mac = '0123456789AB'
      original_inst.source_data = '...'

      duplicate_inst = original_inst.dup

      expect( duplicate_inst.client_mac ).not_to be( original_inst )
      expect( duplicate_inst.client_mac ).to eq( '0123456789AB' )
      expect( duplicate_inst.source_data ).to eq( '...' )
    end

    it "makes safe copy of attributes for duplicate" do
      original_inst = described_class.new
      original_inst.client_mac = '0123456789AB'
      original_inst.source_data = '...'

      duplicate_inst = original_inst.dup
      duplicate_inst.client_mac = 'BA9876543210'
      duplicate_inst.source_data = '###'

      expect( original_inst.client_mac ).to eq( '0123456789AB' )
      expect( original_inst.source_data ).to eq( '...' )
    end
  end

end
