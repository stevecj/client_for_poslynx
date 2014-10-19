# coding: utf-8

module ClientForPoslynx
  class SignatureImage

    class Move
      X_BITS_LONG = 10
      Y_BITS_LONG = 7
      BIT_SEQUENCE_LENGTH = 1 + X_BITS_LONG + Y_BITS_LONG

      def self.first_in_bit_sequence(bit_seq)
        bit_seq.first_bit_digit == '1' &&
          bit_seq.length >= BIT_SEQUENCE_LENGTH
      end

      def self.parse_from_bit_sequence!(bit_seq)
        bit_seq.shift 1
        x_bit_seq = bit_seq.shift( X_BITS_LONG )
        y_bit_seq = bit_seq.shift( Y_BITS_LONG )
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

      def to_bit_sequence
        bit_seq = ClientForPoslynx::BitSequence / '1'
        bit_seq << ClientForPoslynx::BitSequence.from_unsigned( x, X_BITS_LONG )
        bit_seq << ClientForPoslynx::BitSequence.from_unsigned( y, Y_BITS_LONG )
      end
    end

  end
end
