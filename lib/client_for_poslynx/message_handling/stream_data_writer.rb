# coding: utf-8

module ClientForPoslynx
  module MessageHandling

    class StreamDataWriter
      attr_reader :stream

      def initialize(stream)
        @stream = stream
      end

      def put_data(data)
        xml_text = data.xml_serialize
        stream.puts xml_text
      end

    end

  end
end
