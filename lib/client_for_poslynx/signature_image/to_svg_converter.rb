# coding: utf-8

module ClientForPoslynx
  class SignatureImage

    class ToSvgConverter

      class << self

        private :new

        def convert( signature_image )
          new( signature_image ).call
        end

      end

      attr_accessor :signature_image
      private       :signature_image=

      def initialize( signature_image )
        self.signature_image = signature_image
      end

      def call
        apply_document_characteristics

        path_el = svg_document.create_element('path')
        svg_element.add_child path_el

        apply_path_characteristics_to path_el

        path_el['d'] = path_data

        svg_document.to_xml
      end

      private

      def apply_document_characteristics
        metrics = signature_image.metrics || SignatureImage::Metrics.new([6717, 1343], [640, 128])
        svg_element['width'              ] = '%fmm' % ( metrics.size_in_dum[0] * 0.01 )
        svg_element['height'             ] = '%fmm' % ( metrics.size_in_dum[1] * 0.01 )
        svg_element['viewBox'            ] = '0 0 %d %d' % metrics.resolution
        svg_element['preserveAspectRatio'] = 'none'
      end

      def svg_element
        svg_document.root
      end

      def svg_document
        @svg_document ||= begin
          doc = Nokogiri::XML::Document.new
          root_el = doc.root = doc.create_element('svg')
          root_el.default_namespace = 'http://www.w3.org/2000/svg'
          root_el['version'] = '1.1'
          doc
        end
      end

      def apply_path_characteristics_to(path_el)
        apply_stroke_styling_to path_el
        path_el['fill'] = 'none'
      end

      def apply_stroke_styling_to(path_el)
        path_el['stroke'         ] = 'black'
        path_el['stroke-width'   ] = '1mm'
        path_el['stroke-linejoin'] = 'round'
        # Square line cap improves visibility of zero-length
        # lines (dots).
        path_el['stroke-linecap' ] = 'square'
      end

      def path_data
        data = ''
        signature_image.shape_step_groups.each do |shape_steps|
          data << abs_moveto_instruction_for_move_step( shape_steps.first )
          data << rel_lineto_instruction_for_draw_steps( shape_steps[1..-1] )
        end
        data
      end

      def abs_moveto_instruction_for_move_step(step)
        "M #{step.x},#{step.y} "
      end

      def rel_lineto_instruction_for_draw_steps(steps)
        return 'l 0,0 ' if steps.empty?

        steps.reduce( 'l ' ) { |instruction, step|
          instruction << "#{step.dx},#{step.dy} "
        }
      end

    end

  end
end
