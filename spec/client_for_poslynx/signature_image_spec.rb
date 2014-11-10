# coding: utf-8

require 'spec_helper'

module ClientForPoslynx

  describe SignatureImage do

    def build_example_image
      described_class.new.tap { |si|
        si.move  20, 120
        si.draw  10, -30
        si.draw  10, -30
        si.draw  10, -30
        si.draw  10,  30
        si.draw  10,  30
        si.draw  10,  30
        si.move  35,  75
        si.draw  30,  -1
      }
    end

    let( :legacy_bit_sequence ) {
      BitSequence.from_bit_digits( legacy_bit_digit_sequence )
    }

    let( :legacy_bit_digit_sequence ) {
      # TODO: Currently assuming that deltas for move are
      # expressed as sign bit and magnitude, where sign bit
      # of 1 means negative. Documentation is unclear about
      # this though except to say that there is a sign bit,
      # and that values can range from -31 to 31.
      # Once I can connect to the virtual POSLynx again, I
      # need to do a test, and find out whether this
      # assumption is true or not.
      
      '1' + '0000010100' + '1111000' + # move  20, 120 (10-bit, 7-bit)
      '0' + '001010' + '100010' +      # draw  10, -30
      '0' + '001010' + '100010' +      # draw  10, -30
      '0' + '001010' + '100010' +      # draw  10, -30
      '0' + '001010' + '011110' +      # draw  10,  30
      '0' + '001010' + '011110' +      # draw  10,  30
      '0' + '001010' + '011110' +      # draw  10,  30
      '1' + '0000100011' + '1001011' + # move  35,  75  64+8+2+1
      '0' + '011110' + '111111' +      # draw  30,  -1
      '0'                              # remaining bit in last byte
    }

    let( :enhanced_narrow_bit_sequence ) {
      BitSequence.from_bit_digits( enhanced_narrow_bit_digit_sequence )
    }

    let( :enhanced_narrow_bit_digit_sequence ) {
      # TODO: Currently assuming that deltas for move are
      # expressed as sign bit and magnitude, where sign bit
      # of 1 means negative. Documentation is unclear about
      # this though except to say that there is a sign bit,
      # and that values can range from -31 to 31.
      # Once I can connect to the virtual POSLynx again, I
      # need to do a test, and find out whether this
      # assumption is true or not.
      
      '00000000' +                        # 1st byte all 0s: Indicates enhanced format.
      '00001000' +                        # Header content length: 8 bytes
      '0000010000000000' +                # X scaled resolution: 1024 (maximum to be treated as narrow)
      '0000000110000000' +                # Y scaled resolution: 384
      '0001111101000000' +                # X physical size in 0.01 mm units: 8000
      '0000101110111000' +                # Y physical size in 0.01 mm units: 3000
      '1' + '0000010100' + '0001111000' + # move  20, 120 (10-bit, 10-bit)
      '0' + '001010' + '100010' +         # draw  10, -30
      '0' + '001010' + '100010' +         # draw  10, -30
      '0' + '001010' + '100010' +         # draw  10, -30
      '0' + '001010' + '011110' +         # draw  10,  30
      '0' + '001010' + '011110' +         # draw  10,  30
      '0' + '001010' + '011110' +         # draw  10,  30
      '1' + '0000100011' + '0001001011' + # move  35,  75
      '0' + '011110' + '111111' +         # draw  30,  -1
      '000'                               # remaining bits in last byte
    }

    let( :enhanced_wide_bit_sequence ) {
      BitSequence.from_bit_digits( enhanced_wide_bit_digit_sequence )
    }

    let( :enhanced_wide_bit_digit_sequence ) {
      # TODO: Currently assuming that deltas for move are
      # expressed as sign bit and magnitude, where sign bit
      # of 1 means negative. Documentation is unclear about
      # this though except to say that there is a sign bit,
      # and that values can range from -31 to 31.
      # Once I can connect to the virtual POSLynx again, I
      # need to do a test, and find out whether this
      # assumption is true or not.
      
      '00000000' +                         # 1st byte all 0s: Indicates enhanced format.
      '00001000' +                         # Header content length: 8 bytes
      '0000010000000001' +                 # X scaled resolution: 1025 (minimum to be treated as wide)
      '0000000110011010' +                 # Y scaled resolution: 410
      '0001111101000000' +                 # X physical size in 0.01 mm units: 8000
      '0000110010000000' +                 # Y physical size in 0.01 mm units: 3200
      '1' + '00000010100' + '0001111000' + # move  20, 120 (11-bit, 10-bit)
      '0' + '001010' + '100010' +          # draw  10, -30
      '0' + '001010' + '100010' +          # draw  10, -30
      '0' + '001010' + '100010' +          # draw  10, -30
      '0' + '001010' + '011110' +          # draw  10,  30
      '0' + '001010' + '011110' +          # draw  10,  30
      '0' + '001010' + '011110' +          # draw  10,  30
      '1' + '00000100011' + '0001001011' + # move  35,  75
      '0' + '011110' + '111111' +          # draw  30,  -1
      '0'                                  # remaining bit in last byte
    }

    it "is unequal to another instance with a different sequence of steps and no metrics" do
      subject = build_example_image

      other_sig = described_class.new
      other_sig.move 10, 120
      other_sig.draw  0, -29

      expect( subject ).not_to eq( other_sig )
    end

    it "is unequal to another instance with a different sequence of steps and same metrics" do
      subject = build_example_image
      subject.metrics = SignatureImage::Metrics.new([1000, 250], [6080, 1520])

      other_sig = described_class.new
      other_sig.metrics = SignatureImage::Metrics.new([1000, 250], [6080, 1520])
      other_sig.move 10, 120
      other_sig.draw  0, -29

      expect( subject ).not_to eq( other_sig )
    end

    it "is unequal to another instance with the same sequence of steps and different metrics" do
      subject   = build_example_image
      subject.metrics = SignatureImage::Metrics.new([1000, 250], [6080, 1520])

      other_sig = build_example_image
      other_sig.metrics = SignatureImage::Metrics.new([999, 250], [6080, 1520])

      expect( subject ).not_to eq( other_sig )
    end

    it "is equal to another instance with the same sequence of steps and no metrics" do
      subject   = build_example_image
      other_sig = build_example_image

      expect( subject ).to eq( other_sig )
    end

    it "is equal to another instance with the same sequence of steps and same metrics" do
      subject   = build_example_image
      subject.metrics = SignatureImage::Metrics.new([1000, 250], [6080, 1520])

      other_sig = build_example_image
      other_sig.metrics = SignatureImage::Metrics.new([1000, 250], [6080, 1520])

      expect( subject ).to eq( other_sig )
    end

    context "legacy serialized format" do
      context "serializing" do
        subject{ build_example_image }

        it "serializes data" do
          actual_serialized = subject.serialize
          actual_bit_sequence = BitSequence.from_base64( actual_serialized )

          expect( actual_bit_sequence ).to eq( legacy_bit_sequence )
        end
      end

      context "deserializing" do
        subject{ described_class.new(serialized_data) }
        let( :serialized_data ) {
          legacy_bit_sequence.base64_encode
        }

        it "deserializes data" do
          actual = described_class.deserialize( serialized_data )
          expected = build_example_image

          expect( actual ).to eq( expected )
        end
      end
    end

    context "enhanced format with narrow resolution" do
      context "serializing" do
        subject{ build_example_image.tap{ |img|
          img.metrics = SignatureImage::Metrics.new([1024,384], [8000,3000])
        } }

        it "serializes data" do
          actual_serialized = subject.serialize
          actual_bit_sequence = BitSequence.from_base64( actual_serialized )

          expect( actual_bit_sequence ).to eq( enhanced_narrow_bit_sequence )
        end
      end

      context "deserializing" do
        subject{ described_class.new(serialized_data) }
        let( :serialized_data ) {
          enhanced_narrow_bit_sequence.base64_encode
        }

        it "deserializes data" do
          actual = described_class.deserialize( serialized_data )
          expected = build_example_image
          expected.metrics = SignatureImage::Metrics.new([1024,384], [8000,3000])

          expect( actual ).to eq( expected )
        end
      end
    end

    context "enhanced format with wide resolution" do
      context "serializing" do
        subject{ build_example_image.tap{ |img|
          img.metrics = SignatureImage::Metrics.new([1025,410], [8000,3200])
        } }

        it "serializes data" do
          actual_serialized = subject.serialize
          actual_bit_sequence = BitSequence.from_base64( actual_serialized )

          expect( actual_bit_sequence ).to eq( enhanced_wide_bit_sequence )
        end
      end

      context "deserializing" do
        subject{ described_class.new(serialized_data) }
        let( :serialized_data ) {
          enhanced_wide_bit_sequence.base64_encode
        }

        it "deserializes data" do
          actual = described_class.deserialize( serialized_data )
          expected = build_example_image
          expected.metrics = SignatureImage::Metrics.new([1025,410], [8000,3200])

          expect( actual ).to eq( expected )
        end
      end
    end

  end

end
