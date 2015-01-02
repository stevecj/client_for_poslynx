require 'spec_helper'

module ClientForPoslynx

  describe Data::Requests::PinPadReset do

    it_behaves_like "a request data object"

    it "Serializes to a PLRequest XML document for a PPRESET request" do
      mac = Data::Requests::DEFAULT_CLIENT_MAC
      expected_xml =
        "<PLRequest><Command>PPRESET</Command><ClientMAC>#{mac}</ClientMAC></PLRequest>\n"

      expect( subject.xml_serialize ).to eq( expected_xml )
    end


    it "Serializes all assigned members to appropriate elements" do
      subject.client_mac  = 'the-mac'

      expected_xml =
        "<PLRequest><Command>PPRESET</Command><ClientMAC>the-mac</ClientMAC></PLRequest>\n"

      expect( subject.xml_serialize ).to eq( expected_xml )
    end


    it "parses XML data" do
      xml_input = <<-XML
<PLRequest>
  <Command>PPRESET</Command>
</PLRequest>
      XML

      actual_instance = described_class.xml_deserialize xml_input
    end


    it "accepts a canonical visitor" do
      visitor = Object.new
      visitor.extend Data::Requests::CanVisit
      expect{ subject.accept_visitor visitor }.not_to raise_exception
    end

    it "sends itself to an accepted visitor" do
      visitor = double :visitor
      expect( visitor ).to receive( :visit_PinPadReset ).with( subject )
      subject.accept_visitor visitor
    end

  end

end
