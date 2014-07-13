# coding: utf-8

module ClientForPoslynx
  module MessageHandling

    class DataExtractor
      attr_reader :xml_message_source

      def initialize(xml_message_source)
        @xml_message_source = xml_message_source
      end

      def get_data
        xml = xml_message_source.get_message
        Data::AbstractData.xml_parse( xml )
      end

    end

  end
end
