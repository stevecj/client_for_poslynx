# coding: utf-8

require_relative 'signature_image/move'
require_relative 'signature_image/draw'
require_relative 'signature_image/to_svg_converter'

module ClientForPoslynx

  class SignatureImage

    class << self

      def deserialize(serialized_data)
        packed_binary = uudecode( serialized_data )
        bit_seq = ClientForPoslynx::BitSequence.from_packed_bits( packed_binary )

        sig_image = new
        step_types = [ SignatureImage::Move, SignatureImage::Draw ]
        while true
          step_type = step_types.detect{ |st| st.first_in_bit_sequence( bit_seq ) }
          break if step_type.nil?
          step = step_type.parse_from_bit_sequence!( bit_seq )
          sig_image << step
        end

        sig_image
      end

      def uudecode(uuencoded)
        uuencoded.unpack('u').first
      end

    end

    def ==(other)
      return false unless self.class === other
      sequence == other.sequence
    end

    def move(*args)
      sequence << Move.new(*args)
    end

    def draw(*args)
      sequence << Draw.new(*args)
    end

    def <<(step)
      sequence << step
    end

    def each_step
      sequence.each do |step| ; yield step ; end
    end

    def shape_step_groups
      groups = []
      group = []
      sequence.each do |step|
        if SignatureImage::Move === step
          group = []
          groups << group
        end
        group << step
      end
      groups
    end

    def serialize_legacy
      unless Move === sequence.first
        raise 'Must have an initial move-type step in order to serialize'
      end
      bit_seq = ClientForPoslynx::BitSequence.new_empty
      sequence.each do |step|
        bit_seq << step.to_bit_sequence
      end
      bit_seq.uuencode
    end

    protected

    def sequence
      @sequence ||= []
    end

    private

    def pack_binary_digits(digits_string)
      [ digits_string ].pack('B*')
    end

    def uuencode_packed_bits(packed_bits_string)
      [ packed_bits_string ].pack('u')
    end
  end

end
