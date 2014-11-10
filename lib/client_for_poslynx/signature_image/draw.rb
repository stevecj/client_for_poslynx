# coding: utf-8

module ClientForPoslynx
  class SignatureImage

    class Draw
      DELTA_BITS_LONG = 6
      BIT_SEQUENCE_LENGTH = 1 + DELTA_BITS_LONG * 2

      def self.first_in_bit_sequence(bit_seq, format=nil)
        bit_seq.first_bit_digit == '0' &&
          bit_seq.length >= BIT_SEQUENCE_LENGTH
      end

      def self.parse_from_bit_sequence!(bit_seq, format=nil)
        bit_seq.shift 1
        dx_bit_seq = bit_seq.shift( DELTA_BITS_LONG )
        dy_bit_seq = bit_seq.shift( DELTA_BITS_LONG )
        new( dx_bit_seq.as_signed, dy_bit_seq.as_signed )
      end

      attr_reader :dx, :dy

      def initialize(dx, dy)
        @dx = dx
        @dy = dy
      end

      def ==(other)
        return false unless self.class === other
        return dx == other.dx && dy == other.dy
      end

      def to_bit_sequence(serialization_format=nil)
        bit_seq = ClientForPoslynx::BitSequence / '0'
        bit_seq << ClientForPoslynx::BitSequence.from_signed( dx, DELTA_BITS_LONG )
        bit_seq << ClientForPoslynx::BitSequence.from_signed( dy, DELTA_BITS_LONG )
      end

    end

  end
end
