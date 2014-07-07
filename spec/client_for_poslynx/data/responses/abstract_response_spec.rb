require 'spec_helper'

module ClientForPoslynx

  describe Data::Responses::AbstractResponse do
    subject{ described_class }

    it "Returns a populated instance of CreditCardSaleRequest for CCSALE response XML" do
      xml_input = <<XML
<#{Data::Responses::ROOT_ELEMENT_NAME}>
  <Command>CCSALE</Command>
  <Result>the-result</Result>
</#{Data::Responses::ROOT_ELEMENT_NAME}>
XML
      actual_result_data = subject.xml_parse( xml_input )

      expect( actual_result_data.result ).to eq( 'the-result' )
    end

    it "Returns a populated instance of PinPadInitialize for PPINIT command XML" do
      xml_input = <<XML
<#{Data::Responses::ROOT_ELEMENT_NAME}>
  <Command>PPINIT</Command>
  <Result>the-result</Result>
</#{Data::Responses::ROOT_ELEMENT_NAME}>
XML
      actual_result_data = subject.xml_parse( xml_input )

      expect( actual_result_data.result ).to eq( 'the-result' )
    end
  end

end
