require 'spec_helper'

module ClientForPoslynx

  describe Data::Requests::PinPadInitialize do


    it "Serializes to a PLRequest XML document for a CCSALE request" do
      mac = Data::Requests::DEFAULT_CLIENT_MAC
      expected_xml =
        "<PLRequest><Command>PPINIT</Command><ClientMAC>#{mac}</ClientMAC></PLRequest>\n"

      expect( subject.xml_serialize ).to eq( expected_xml )
    end


    it "Serializes all assigned members to appropriate elements" do
      subject.client_mac  = 'the-mac'
      subject.idle_prompt = 'the-prompt'

      expected_xml =
        "<PLRequest><Command>PPINIT</Command><ClientMAC>the-mac</ClientMAC><IdlePrompt>the-prompt</IdlePrompt></PLRequest>\n"

      expect( subject.xml_serialize ).to eq( expected_xml )
    end


    it "raises InvalidXmlContentError deserializing XML with missing Command element" do
      xml_input = <<-XML
<PLRequest>
</PLRequest>
      XML

      expect {
        described_class.xml_deserialize xml_input
      }.to raise_exception( InvalidXmlContentError )
    end


    it "raises InvalidXmlContentError deserializing XML with wrong Command value" do
      xml_input = <<-XML
<PLRequest>
  <Command>DOSOMETHING</Command>
</PLRequest>
      XML

      expect {
        described_class.xml_deserialize xml_input
      }.to raise_exception( InvalidXmlContentError )
    end


    it "parses minimally acceptable XML data" do
      xml_input = <<-XML
<PLRequest>
  <Command>PPINIT</Command>
</PLRequest>
      XML

      actual_instance = described_class.xml_deserialize xml_input
      expect( actual_instance.idle_prompt ).to be_nil
    end


    it "parses XML data with all property elements supplied" do
      xml_input = <<-XML
<PLRequest>
  <Command>PPINIT</Command>
  <ClientMAC>the-MAC</ClientMAC>
  <IdlePrompt>the-prompt</IdlePrompt>
</PLRequest>
      XML

      actual_instance = described_class.xml_deserialize xml_input

      expect( actual_instance.client_mac  ).to eq( 'the-MAC'    )
      expect( actual_instance.idle_prompt ).to eq( 'the-prompt' )
    end


    it "accepts a canonical visitor" do
      visitor = Object.new
      visitor.extend Data::Requests::CanVisit
      expect{ subject.accept_visitor visitor }.not_to raise_exception
    end

    it "sends itself to an accepted visitor" do
      visitor = double :visitor
      expect( visitor ).to receive( :visit_PinPadInitialize ).with( subject )
      subject.accept_visitor visitor
    end

  end

end
