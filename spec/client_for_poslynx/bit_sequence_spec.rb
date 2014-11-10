# coding: binary
# Note that "binary" coding is important for this file
# since that allows us to write packed binary string
# literals.

require 'spec_helper'
require 'stringio'

module ClientForPoslynx

  describe BitSequence do
    subject{ klass ^ "Do" }
    let( :klass ) { described_class }

    specify "is unequal to another instance based on different packed bits" do
      other_instance = klass ^ "Re"
      expect( subject ).not_to eq( other_instance )
    end

    specify "is equal to another instance based on same packed bits" do
      other_instance = klass ^ "Do"
      expect( subject ).to eq( other_instance )
    end

    specify "is unequal to another instance based on a non-equivalent binary digit sequence" do
      other_instance = klass / "1010101010101010"
      expect( subject ).not_to eq( other_instance )
    end

    specify "is equal to another instance based on an equivalent binary digit sequence" do
      other_instance = klass / "0100010001101111"
      expect( subject ).to eq( other_instance )
    end

    it "sets extra bits in final byte to zeros when packing bits" do
      instance = klass / "01110000111"
      expect( instance.to_packed_bits ).to eq( "\x70\xE0" )
    end

    it "correctly reports how many bits long it is" do
      expect(   klass.new_empty     .length ).to eq(  0 )
      expect( ( klass / '0'        ).length ).to eq(  1 )
      expect( ( klass / '10'       ).length ).to eq(  2 )
      expect( ( klass / ('01' * 9) ).length ).to eq( 18 )
    end

    it "correctly reports what its first bit-digit is" do
      expect( ( klass /  '101' ).first_bit_digit ).to eq( '1' )
      expect( ( klass / '1101' ).first_bit_digit ).to eq( '1' )
      expect( ( klass /  '001' ).first_bit_digit ).to eq( '0' )
      expect( ( klass / '0101' ).first_bit_digit ).to eq( '0' )
    end

    it "can have another bit sequence pushed onto its end" do
      actual =  klass / '10101'
      actual << klass / '001100'
      expected = klass / '10101001100'
      expect( actual ).to eq( expected )
    end

    it "can have a bit sequence shifted off of its front" do
      bit_source = klass / '111000111000111000'
      taken = bit_source.shift(9)

      expected_remaining = klass / '000111000'
      expected_taken     = klass / '111000111'

      expect( bit_source ).to eq( expected_remaining )
      expect( taken      ).to eq( expected_taken     )
    end

    it "can have another bit sequence unshifted onto its front" do
      bit_target = klass / '000111000'
      bit_target.unshift klass / '111000111'

      expected_resulting = klass / '111000111000111000'

      expect( bit_target ).to eq( expected_resulting )
    end

    it "can be (big-endian) interpreted as an unsigned integer" do
      expect( ( klass / '111000011110000'  ).as_unsigned ).to eq( 0x70F0 )
      expect( ( klass / ( '11110000' * 8 ) ).as_unsigned ).to eq( 0xF0F0F0F0F0F0F0F0 )
    end

    it "fails to be interpreted as unsigned if longer than 64 bits" do
      bit_seq = klass / ( '11110000' * 8 + '1' )
      expect{ bit_seq.as_unsigned }.to \
        raise_exception( klass::TooManyBitsLong, /\b64\b/ )
    end

    it "can be (big-endian) interpreted as a 2s-complement signed integer" do
      expect( ( klass / '000'              ).as_signed ).to eq(   0 )
      expect( ( klass / '0111000011110000' ).as_signed ).to eq(   0x70F0 )
      expect( ( klass / '1000111100010000' ).as_signed ).to eq( - 0x70F0 )
      expect( ( klass / ('11110000' * 8)   ).as_signed ).to eq( - 0x0F0F0F0F0F0F0F10 )
    end

    it "fails to be interpreted as 2s complement if longer than 64 bits" do
      bit_seq = klass / ( '0' + '11110000' * 8 )
      expect{ bit_seq.as_signed }.
        to raise_exception( klass::TooManyBitsLong, /\b64\b/ )
    end

    it "can be constructed as the big-endian representation of an unsigned integer" do
      expect( klass.from_unsigned(  0,             9 ) ).to eq( klass / ( '0' * 9   ) )
      expect( klass.from_unsigned(  0x23,          7 ) ).to eq( klass / ( '0100011' ) )
      expect( klass.from_unsigned( (2 ** 64) - 1, 64 ) ).to eq( klass / ( '1' * 64  ) )
    end

    it "fails to be constructed as a longer than 64-bit representation of an unsigned number" do
      expect{ klass.from_unsigned(0x23, 65) }.
        to raise_exception( klass::TooManyBitsLong, /\b64\b/ )
    end

    it "fails to be constructed as an unsigned representation a negative number" do
      expect{ klass.from_unsigned(-1, 5) }.
        to raise_exception( klass::NumberOutOfBounds )
    end

    it "fails to be constructed as an under-sized representation of an unsigned number" do
      expect{ klass.from_unsigned(0x23, 5) }.
        to raise_exception( klass::NumberOutOfBounds )
    end

    it "can be constructed as the big-endian, 2's complement representation of a signed integer" do
      expect( klass.from_signed(   0,         9 ) ).to eq( klass / ( '0' * 9   ) )
      expect( klass.from_signed(  -0x23,      7 ) ).to eq( klass / ( '1011101' ) )
      expect( klass.from_signed(  -1,         4 ) ).to eq( klass / ( '1111'    ) )
      expect( klass.from_signed( -(2 ** 63), 64 ) ).to eq( klass / ( '1' + '0' * 63  ) )
    end

    it "fails to be constructed as a longer than 64-bit representation of a signed number" do
      expect{ klass.from_signed(0x23, 65) }.
        to raise_exception( klass::TooManyBitsLong, /\b64\b/ )
    end

    it "fails to be constructed as a  an under-sized representation a negative signed number" do
      expect{ klass.from_signed(-0x23, 6) }.
        to raise_exception( klass::NumberOutOfBounds )
    end

    it "fails to be constructed as an under-sized representation of a positive signed number" do
      expect{ klass.from_signed(0x23, 6) }.
        to raise_exception( klass::NumberOutOfBounds )
    end

    it "can be build by unpacking bits from a base-64 encoded string" do
      actual   = klass.from_base64( "MjIyMjIy" )
      expected = klass ^ "\x32" * 6

      expect( actual ).to eq( expected )
    end

    it "can be packed to a base-64 string" do
      bit_seq = klass ^ "\x32" * 6
      expect( bit_seq.base64_encode ).to eq( "MjIyMjIy" )
    end

  end

end
