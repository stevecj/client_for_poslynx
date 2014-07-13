# coding: utf-8

require 'spec_helper'
require 'stringio'

module ClientForPoslynx

  describe MessageHandling::XmlExtractor do

    it "reads discrete, new-line terminated XML messages from a peristent stream" do
      # We can rely on the POSLynx to start a root opening tag at
      # beginning of a line and to end a root closing tag at the
      # end of a line. Different versions of POSLynx have had
      # different behavior regarding whether to pretty-format each
      # XML message or to run it together on a single line, so we
      # should handle both cases.
      # Also, we can assume there will never be a self-closing root
      # element tag.

      input_data = <<-XML
<TheRoot><AChild/></TheRoot>

<AnotherRoot >
  <AnotherChild/>
</AnotherRoot>
<YetAnother></YetAnother >
      XML

      input_data.chomp! # Without newline at end of input stream.
      stream = StringIO.new(input_data)
      extractor = described_class.new(stream)

      messages = 3.times.map{ extractor.get_message }

      expect( messages ).to eq( [
        "<TheRoot><AChild/></TheRoot>\n",
        "\n<AnotherRoot >\n  <AnotherChild/>\n</AnotherRoot>\n",
        "<YetAnother></YetAnother >",
      ] )
    end

  end

end
