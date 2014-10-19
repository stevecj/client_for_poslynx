# coding: utf-8

require 'spec_helper'

module ClientForPoslynx

  describe SignatureImage::ToSvgConverter do
    let( :svg_ns ) { 'http://www.w3.org/2000/svg' }
    let( :signature_image ) { SignatureImage.new }
    let( :svg_doc_content ) { described_class.convert( signature_image ) }
    let( :svg_document ) {
      Nokogiri::XML( svg_doc_content ) do |config|
        config.options = Nokogiri::XML::ParseOptions::STRICT | Nokogiri::XML::ParseOptions::NONET
      end
    }
    let( :svg_doc_root ) { svg_document.root }

    it "produces SVG document content" do
      expect( svg_doc_root.name ).to eq( 'svg' )
      expect( svg_doc_root.namespace.href ).to eq( svg_ns )
      expect( svg_doc_root['version'] ).to eq( '1.1' )
    end

    it "specifies physical dimensions in millimeter units" do
      expected = /^\d+([.]\d*)?mm?$/
      expect( svg_doc_root['width' ] ).to match( expected )
      expect( svg_doc_root['height'] ).to match( expected )
    end

    it "specifies integer logical units for view box start and size" do
      expect( svg_doc_root['viewBox'] ).to match( /^(\d+\s+){3}\d+$/ )
    end

    it "treats logical units as fractions of physical dimensions, regardless of resulting pixel aspect ratio" do
      expect( svg_doc_root['preserveAspectRatio'] ).to eq( 'none' )
    end

    it "includes a an SVG <path> element" do
      expect( svg_document.xpath('//ns:svg/ns:path', 'ns' => svg_ns).length ).
        to eq( 1 )
    end

    describe "<path> element" do
      let( :svg_path_element ) {
        svg_document.at_xpath('//ns:svg/ns:path', 'ns' => svg_ns)
      }

      it "has a black stroke color" do
        expect( svg_path_element['stroke'] ).to eq( 'black' )
      end

      it "is explicitly not filled" do
        expect( svg_path_element['fill'] ).to eq( 'none' )
      end

      it "has a stroke width in millimeter units" do
        expected = /^\d+([.]\d*)?mm?$/
        expect( svg_path_element['stroke-width'] ).to match( expected )
      end

      describe "path data" do
        let( :svg_path_instruction_tokens ) {
          path_data = svg_path_element['d']
          path_instructions = path_data.split(/ (?=[Ml])/)
          path_instructions.map { |pi|
            instr_type = pi[0..0]
            instr_values = pi[1..-1].strip.split(/[ ,]+/)
            [ instr_type ] + instr_values
          }
        }

        it "creates path data from signature data steps" do
          signature_image.move 25, 20
          signature_image.draw 30,  1

          signature_image.move 10, 20
          signature_image.draw  0, 30
          signature_image.draw -1, 25

          expect( svg_path_instruction_tokens ).to eq( [
            %w[ M 25 20 ],
            %w[ l 30 1 ],

            %w[ M 10 20 ],
            %w[ l  0 30
                  -1 25 ],
          ] )
        end

        it "adds zero length line-to after a move without a draw" do
          signature_image.move 25, 20
          signature_image.draw 30,  1

          signature_image.move 10, 20

          signature_image.move 90, 30
          signature_image.draw -1, 25

          expect( svg_path_instruction_tokens ).to eq( [
            %w[ M 25 20 ],
            %w[ l 30 1 ],

            %w[ M 10 20 ],
            %w[ l 0 0 ],

            %w[ M 90 30 ],
            %w[ l -1 25 ],
          ] )
        end
      end
    end
  end

end
