# coding: utf-8

require_relative 'signature_image/metrics'
require_relative 'signature_image/move'
require_relative 'signature_image/draw'
require_relative 'signature_image/to_svg_converter'

module ClientForPoslynx

  class SignatureImage

    class << self

      def deserialize(serialized_data)
        packed_binary = base64_decode( serialized_data )
        bit_seq = ClientForPoslynx::BitSequence.from_packed_bits( packed_binary )

        sig_image = new

        if bit_seq.first_bit_digit == '0' then
          leader_seq = bit_seq.shift( 16 )
          header_content_length_bytes = leader_seq.as_unsigned
          if header_content_length_bytes < 8 then
            # TODO: Should have an exception class for this error.
            raise "Expected header content length to be >= 8, but got #{header_content_length}."
          end
          if header_content_length_bytes > 255 then
            # TODO: Should have an exception class for this error.
            byte_0_bit_digits = leader_seq.to_bit_digits[0..7]
            raise "Expected first byte of leader to be zero, but got #{byte_0_bit_digits}."
          end
          header_content_seq = bit_seq.shift( header_content_length_bytes * 8 )
          x_scaled_res = header_content_seq.shift(16).as_unsigned
          y_scaled_res = header_content_seq.shift(16).as_unsigned
          x_phys_size  = header_content_seq.shift(16).as_unsigned
          y_phys_size  = header_content_seq.shift(16).as_unsigned
          sig_image.metrics = SignatureImage::Metrics.new(
            [ x_scaled_res, y_scaled_res ],
            [ x_phys_size,  y_phys_size  ],
          )
        end

        format = sig_image.serialization_format

        step_types = [ SignatureImage::Move, SignatureImage::Draw ]
        while true
          step_type = step_types.detect{ |st| st.first_in_bit_sequence( bit_seq, format ) }
          break if step_type.nil?
          step = step_type.parse_from_bit_sequence!( bit_seq, format )
          sig_image << step
        end

        sig_image
      end

      def base64_decode(encoded)
        encoded.unpack('m').first
      end

    end

    attr_accessor :metrics

    def ==(other)
      return false unless self.class === other
      metrics == other.metrics &&
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

    def serialize
      unless Move === sequence.first
        raise 'Must have an initial move-type step in order to serialize'
      end
      bit_seq = ClientForPoslynx::BitSequence.new_empty
      case serialization_format
      when :enhanced_narrow, :enhanced_wide
        bit_seq << ClientForPoslynx::BitSequence / '00000000'
        bit_seq << ClientForPoslynx::BitSequence / '00001000'
        bit_seq << ClientForPoslynx::BitSequence.from_unsigned( metrics.resolution[0], 16 )
        bit_seq << ClientForPoslynx::BitSequence.from_unsigned( metrics.resolution[1], 16 )
        bit_seq << ClientForPoslynx::BitSequence.from_unsigned( metrics.size_in_dum[0], 16 )
        bit_seq << ClientForPoslynx::BitSequence.from_unsigned( metrics.size_in_dum[1], 16 )
      end
      sequence.each do |step|
        bit_seq << step.to_bit_sequence( serialization_format )
      end
      bit_seq.base64_encode
    end

    def serialization_format
      if metrics.nil?
        :legacy
      else
        metrics.resolution[0] > 1024 ?
          :enhanced_wide :
          :enhanced_narrow
      end
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
