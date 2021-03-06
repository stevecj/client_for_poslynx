# coding: utf-8

module ClientForPoslynx
  module MessageHandling

    # TODO: This is now obsolete and being replaced by a combina-
    # tion of EventMachine's LineProtocol and XmlLinesBuffer.
    # This class should be removed as soon as the fake POS
    # terminal code has been re-built as an EM server.
    class XmlExtractor
      attr_reader :stream

      def initialize(stream)
        @stream = stream
      end

      def get_message
        # It would be better to use an XML parser to find the boun-
        # daries of an XML document, but I have had no luck getting
        # Nokogiri to do that job for me. It keeps reading from the
        # stream after the end of the closing tag.
        # This alternative solution is pretty solid. It could be
        # tricked by something like text matching a root closing
        # tag at the end of a line within a cdata block, but I
        # think that's a sufficiently negligible risk.
        message = ''
        root_name = nil
        while true
          line = stream.gets
          message << line
          if (! root_name) && line =~ /^(?:<\?.+?\?>)?<([A-Za-z_][^\s>]*)[ >]/
            root_name = $1
          end
          break if root_name && line =~ /<\/#{root_name}\s*>\s*$/
        end
        message
      end

    end

  end
end
