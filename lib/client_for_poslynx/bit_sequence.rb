# coding: binary

module ClientForPoslynx
  class BitSequence
    class TooManyBitsLong   < StandardError ; end
    class NumberOutOfBounds < StandardError ; end

    class << self
      private :new

      def from_packed_bits(packed_string)
        digits_string = packed_string.unpack('B*').first
        from_bit_digits( digits_string )
      end

      alias ^ from_packed_bits

      def new_empty
        from_bit_digits('')
      end

      def from_bit_digits(digits_string)
        new( digits_string )
      end

      alias / from_bit_digits

      def from_unsigned(value, seq_length)
        if seq_length > 64
          raise TooManyBitsLong, "Can't build a representation more than 64 bits long from an unsigned number"
        end
        if value < 0
          raise NumberOutOfBounds, "Can't build an unsigned representation of a negative number"
        end
        if value >= 2 ** seq_length
          raise NumberOutOfBounds, "The largest value representable in #{seq_length} bits is less than #{value}"
        end
        packed_bits = [ value ].pack('Q>')
        bit_seq = from_packed_bits( packed_bits )
        bit_seq.shift( 64 - seq_length )
        bit_seq
      end

      def from_sign_and_magnitude_of(value, seq_length)
        magnitude = value.abs
        magnitude_seq = from_unsigned( magnitude, seq_length - 1 )
        sign_bit = from_bit_digits( value < 0 ? '1' : '0' )
        magnitude_seq.unshift( sign_bit )
      end

      def from_base64(encoded)
        packed_bits = encoded.unpack('m0').first
        from_packed_bits( packed_bits )
      end
    end

    def initialize(digits_string)
      @digits_string = digits_string
    end

    def inspect
      "#<#{self.class.name}: #{pretty_digits}>"
    end

    def pretty_digits
      nibbles = digits_string.scan(/.{1,4}/)
      bytes = nibbles.each_slice(2).map{ |n| n.join(' ') }
      bytes.join('  ')
    end

    def ==(other)
      return false unless other.respond_to?( :to_bit_digits )
      digits_string == other.to_bit_digits
    end

    def to_packed_bits
      [ digits_string ].pack('B*')
    end

    def to_bit_digits
      digits_string
    end

    def base64_encode
      [ to_packed_bits ].pack('m0')
    end

    def length
      digits_string.length
    end

    def first_bit_digit
      digits_string[0..0]
    end

    def push(sequence)
      digits_string << sequence.to_bit_digits
      self
    end

    alias << push

    def shift(bit_count)
      digits_taken = digits_string[0...bit_count]
      digits_string[0...bit_count] = ''
      self.class.from_bit_digits( digits_taken )
    end

    def unshift( bit_sequence )
      digits_string[0...0] = bit_sequence.to_bit_digits
      self
    end

    def as_unsigned
      if length > 64
        raise TooManyBitsLong,
          "Cannot coerce sequence longer than 64 bits to unsigned number"
      end
      little_endian_digits = digits_string.reverse + '0' * 64
      packed_little_endian = [ little_endian_digits ].pack('b*')
      packed_little_endian.unpack('Q<').first
    end

    def as_sign_and_magnitude
      if length > 65
        raise TooManyBitsLong,
          "Cannot coerce sequence longer than 65 bits to unsigned number"
      end
      magnitude_seq = self.class.from_bit_digits( digits_string[1..-1] )
      magnitude = magnitude_seq.as_unsigned
      first_bit_digit == '1' ? - magnitude : magnitude
    end

    private

    attr_reader :digits_string

  end
end
