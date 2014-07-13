require 'spec_helper'

module ClientForPoslynx

  describe Data::AbstractData do

    subject{ described_class }


    it "Parses XML for a CCSALE command to a Request::CreditCardSaleRequest instance" do
      xml_input = <<-XML
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


    it "Parses XML for a PPINIT command to a Request::PinPadInitialize instance" do
      xml_input = <<-XML
<PLRequest>
  <Command>PPINIT</Command>
  <IdlePrompt>the-prompt</IdlePrompt>
</PLRequest>
      XML

      actual_request_data = subject.xml_parse( xml_input )
      expect( actual_request_data.idle_prompt ).to eq( 'the-prompt' )
    end


    it "Parses XML for a CCSALE response to a Response::CreditCardSaleRequest instance" do
      xml_input = <<-XML
<PLResponse>
  <Command>CCSALE</Command>
  <Result>the-result</Result>
</PLResponse>
      XML

      actual_result_data = subject.xml_parse( xml_input )
      expect( actual_result_data.result ).to eq( 'the-result' )
    end


    it "Parses XML for a PPINIT response to a Response::PinPadInitialize instance" do
      xml_input = <<-XML
<PLResponse>
  <Command>PPINIT</Command>
  <Result>the-result</Result>
</PLResponse>
      XML

      actual_result_data = subject.xml_parse( xml_input )
      expect( actual_result_data.result ).to eq( 'the-result' )
    end


  end

end
