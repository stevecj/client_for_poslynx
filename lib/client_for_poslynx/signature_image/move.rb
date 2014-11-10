# coding: utf-8

module ClientForPoslynx
  class SignatureImage

    class Move
      X_BITS_LONG = { legacy: 10, enhanced_narrow: 10, enhanced_wide: 11 }
      Y_BITS_LONG = { legacy: 7,  enhanced_narrow: 10, enhanced_wide: 10 }

      def self.first_in_bit_sequence(bit_seq, format=:legacy)
        bit_sequence_length = 1 + X_BITS_LONG[format] + Y_BITS_LONG[format]
        bit_seq.first_bit_digit == '1' &&
          bit_seq.length >= bit_sequence_length
      end

      def self.parse_from_bit_sequence!(bit_seq, format=:legacy)
        bit_seq.shift 1
        x_bit_seq = bit_seq.shift( X_BITS_LONG[format] )
        y_bit_seq = bit_seq.shift( Y_BITS_LONG[format] )
        new( x_bit_seq.as_unsigned, y_bit_seq.as_unsigned )
      end

      attr_reader :x, :y

      def initialize(x,y)
        @x = x
        @y = y
      end

      def ==(other)
        return false unless self.class === other
        return x == other.x && y == other.y
      end

      def to_bit_sequence(format=:legacy)
        bit_seq = ClientForPoslynx::BitSequence / '1'
        bit_seq << ClientForPoslynx::BitSequence.from_unsigned( x, X_BITS_LONG[format] )
        bit_seq << ClientForPoslynx::BitSequence.from_unsigned( y, Y_BITS_LONG[format] )
      end
    end

  end
end
