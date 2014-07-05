require 'spec_helper'

module ClientForPoslynx

  describe Data::CreditCardSaleRequest do

    it "Serializes to a PLRequest XML document for a CCSALE command" do
      expected_xml = <<XML
<?xml version="1.0"?>
<PLRequest>
  <Command>CCSALE</Command>
</PLRequest>
XML
      expect( subject.xml_serialize ).to eq( expected_xml )
    end

  end

end
