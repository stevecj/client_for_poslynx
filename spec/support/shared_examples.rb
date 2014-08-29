# coding: utf-8

module ClientForPoslynx

  RSpec.shared_examples "a data object" do

    it "raises InvalidXmlError deserializing invalid XML" do
      expect {
        described_class.xml_deserialize "I am not valid XML"
      }.to raise_exception( InvalidXmlError )
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

  end

end
