require 'spec_helper'

module ClientForPoslynx

  describe Data::Requests::PinPadDisplaySpecifiedForm do

    it_behaves_like "a request data object"

    it "Serializes to an XML document for a PPSPECIFIEDFORM request" do
      mac = Data::Requests::DEFAULT_CLIENT_MAC
      expected_xml =
        "<PLRequest><Command>PPSPECIFIEDFORM</Command><ClientMAC>#{mac}</ClientMAC></PLRequest>\n"

      expect( subject.xml_serialize ).to eq( expected_xml )
    end


    it "Serializes all assigned members to appropriate elements" do
      subject.client_mac    = 'the-MAC'
      subject.form_name     = 'the-form'
      subject.text_values   = ['text-1', 'text-2']
      subject.button_labels = ['Button A', 'Button B']

      expected_xml =
        "<PLRequest>" +
          "<Command>PPSPECIFIEDFORM</Command>" +
          "<ClientMAC>the-MAC</ClientMAC>" +
          "<FormName>the-form</FormName>" +
          "<Text>text-1|text-2</Text>" +
          "<Buttons>Button A|Button B</Buttons>" +
        "</PLRequest>\n"

      expect( subject.xml_serialize ).to eq( expected_xml )
    end


    it "parses minimally acceptable XML data" do
      xml_input = <<-XML
<PLRequest>
  <Command>PPSPECIFIEDFORM</Command>
</PLRequest>
      XML

      actual_instance = described_class.xml_deserialize xml_input
      expect( actual_instance.form_name     ).to be_nil
      expect( actual_instance.text_values   ).to be_nil
      expect( actual_instance.button_labels ).to be_nil
    end


    it "parses XML data with all property elements supplied" do
      xml_input = <<-XML
<PLRequest>
  <Command>PPSPECIFIEDFORM</Command>
  <ClientMAC>the-MAC</ClientMAC>
  <FormName>the-form</FormName>
  <Text>text-1|text-2</Text>
  <Buttons>button-a|button-b</Buttons>
</PLRequest>
      XML

      actual_instance = described_class.xml_deserialize xml_input

      expect( actual_instance.client_mac    ).to eq( 'the-MAC' )
      expect( actual_instance.form_name     ).to eq( 'the-form' )
      expect( actual_instance.text_values   ).to eq( ['text-1', 'text-2' ] )
      expect( actual_instance.button_labels ).to eq( ['button-a', 'button-b' ] )
    end

    it "accepts a canonical visitor" do
      visitor = Object.new
      visitor.extend Data::Requests::CanVisit
      expect{ subject.accept_visitor visitor }.not_to raise_exception
    end

    it "sends itself to an accepted visitor" do
      visitor = double :visitor
      expect( visitor ).to receive( :visit_PinPadDisplaySpecifiedForm ).with( subject )
      subject.accept_visitor visitor
    end

  end

end
