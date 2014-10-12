# coding: utf-8

require 'spec_helper'

module ClientForPoslynx

  describe SignatureImage do

    def build_example_image
      described_class.new.tap { |si|
        si.move  10, 120
        si.draw   0, -30
        si.draw   0, -30
        si.draw   0, -30
        si.draw   0, -20
        si.draw  30,  30
        si.draw -25,  25
        si.draw   0,  -2
      }
    end

    let( :bit_sequence ) {
      BitSequence.from_bit_digits( bit_digit_sequence )
    }

    let( :bit_digit_sequence ) {
      # TODO: Currently assuming that deltas for move are
      # expressed as sign bit and magnitude, where sign bit
      # of 1 means negative. Documentation is unclear about
      # this though except to say that there is a sign bit,
      # and that values can range from -31 to 31.
      # Once I can connect to the virtual POSLynx again, I
      # need to do a test, and find out whether this
      # assumption is true or not.
      
      '1' + '0000001010' + '1111000' + # move  10, 120
      '0' + '000000' + '111110' +      # draw   0, -30
      '0' + '000000' + '111110' +      # draw   0, -30
      '0' + '000000' + '111110' +      # draw   0, -30
      '0' + '000000' + '110100' +      # draw   0, -20
      '0' + '011110' + '011110' +      # draw  30,  30
      '0' + '111001' + '011001' +      # draw -25,  25
      '0' + '000000' + '100010' +      # draw   0,  -2
      '000'                            # remaining bits in last byte
    }

    it "is unequal to another instance with a different sequence of steps" do
      subject = build_example_image

      other_sig = described_class.new
      other_sig.move 10, 120
      other_sig.draw  0, -29

      expect( subject ).not_to eq( other_sig )
    end

    it "is equal to another instance with the same sequence of steps" do
      subject   = build_example_image
      other_sig = build_example_image

      expect( subject ).to eq( other_sig )
    end

    context "serializing" do
      subject{ build_example_image }

      it "serializes data in legacy format" do
        actual_serialized = subject.serialize_legacy
        actual_bit_sequence = BitSequence.from_uuencoded( actual_serialized )

        expect( actual_bit_sequence ).to eq( bit_sequence )
      end
    end

    context "deserializing" do
      subject{ described_class.new(serialized_data) }
      let( :serialized_data ) {
        bit_sequence.uuencode
      }

      it "deserializes data from legacy format" do
        actual = described_class.deserialize( serialized_data )
        expected = build_example_image

        expect( actual ).to eq( expected )
      end
    end

  end

end
