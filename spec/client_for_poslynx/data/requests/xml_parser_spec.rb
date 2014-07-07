require 'spec_helper'

module ClientForPoslynx

  describe Data::Requests::XmlParser do

    it "Returns a populated instance of CreditCardSaleRequest for CCSALE command XML" do
      xml_input = <<XML
<PLRequest>
  <Command>CCSALE</Command>
  <Id>the-transaction</Id>
  <Amount>the-amount</Amount>
  <CardNumber>the-number</CardNumber>
</PLRequest>
XML
      actual_request_data = subject.xml_parse( xml_input )

      expect( actual_request_data.merchant_supplied_id ).to eq( 'the-transaction' )
      expect( actual_request_data.amount               ).to eq( 'the-amount'      )
      expect( actual_request_data.card_number          ).to eq( 'the-number'      )
    end

    it "Returns a populated instance of PinPadInitialize for PPIINIT command XML" do
      xml_input = <<XML
<PLRequest>
  <Command>PPINIT</Command>
  <IdlePrompt>the-prompt</IdlePrompt>
</PLRequest>
XML
      actual_request_data = subject.xml_parse( xml_input )

      expect( actual_request_data.idle_prompt ).to eq( 'the-prompt' )
    end
  end

end
