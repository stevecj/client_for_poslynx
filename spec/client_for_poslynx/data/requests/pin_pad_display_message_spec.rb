require 'spec_helper'

module ClientForPoslynx

  describe Data::Requests::PinPadDisplayMessage do

    it_behaves_like "a data object"

    it "Serializes to a PLRequest XML document for a PPDISPLAY request" do
      mac = Data::Requests::DEFAULT_CLIENT_MAC
      expected_xml =
        "<PLRequest><Command>PPDISPLAY</Command><ClientMAC>#{mac}</ClientMAC></PLRequest>\n"

      expect( subject.xml_serialize ).to eq( expected_xml )
    end


    it "Serializes all assigned members to appropriate elements" do
      subject.client_mac    = 'the-mac'
      subject.line_count    =  2
      subject.text_lines    = ['Line 1', 'Line 2']
      subject.button_labels = ['Button A', 'Button B']

      expected_xml =
        "<PLRequest>" +
          "<Command>PPDISPLAY</Command>" +
          "<ClientMAC>the-mac</ClientMAC>" +
          "<Lines>2</Lines>" +
          "<Text>Line 1|Line 2</Text>" +
          "<Buttons>Button A|Button B</Buttons>" +
        "</PLRequest>\n"

      expect( subject.xml_serialize ).to eq( expected_xml )
    end


    it "parses minimally acceptable XML data" do
      xml_input = <<-XML
<PLRequest>
  <Command>PPDISPLAY</Command>
</PLRequest>
      XML

      actual_instance = described_class.xml_deserialize xml_input
      expect( actual_instance.line_count ).to be_nil
    end


    it "parses XML data with all property elements supplied" do
      xml_input = <<-XML
<PLRequest>
  <Command>PPDISPLAY</Command>
  <ClientMAC>the-MAC</ClientMAC>
  <Lines>the-line-count</Lines>
  <Text>Line 1|Line 2</Text>
  <Buttons>Label A|Label B</Buttons>
</PLRequest>
      XML

      actual_instance = described_class.xml_deserialize xml_input

      expect( actual_instance.client_mac  ).to eq( 'the-MAC'    )
      expect( actual_instance.line_count ).to eq( 'the-line-count' )
      expect( actual_instance.text_lines ).to eq( ['Line 1', 'Line 2'] )
      expect( actual_instance.button_labels ).to eq( ['Label A', 'Label B'] )
    end


    it "accepts a canonical visitor" do
      visitor = Object.new
      visitor.extend Data::Requests::CanVisit
      expect{ subject.accept_visitor visitor }.not_to raise_exception
    end

    it "sends itself to an accepted visitor" do
      visitor = double :visitor
      expect( visitor ).to receive( :visit_PinPadDisplayMessage ).with( subject )
      subject.accept_visitor visitor
    end

  end

end
