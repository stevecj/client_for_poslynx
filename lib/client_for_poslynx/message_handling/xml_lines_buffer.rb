# coding: utf-8

module ClientForPoslynx
  module MessageHandling

    class XmlLinesBuffer
      def initialize
        reset
      end

      def add_line(line)
        message << line
        if (! root_name) && line =~ /^(?:<\?.+?\?>)?<([A-Za-z_][^\s>]*)[ >]/
          self.root_name = $1
        end
        if root_name && line =~ /<\/#{root_name}\s*>\s*$/
          complete_message = message
          reset
          yield complete_message
        end
      end

      private

      attr_reader   :message
      attr_accessor :root_name

      def reset
        @message   = ''
        @root_name = nil
      end
    end

  end
end
