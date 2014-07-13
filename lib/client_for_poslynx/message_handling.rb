# coding: utf-8

require_relative 'message_handling/xml_extractor'
require_relative 'message_handling/data_extractor'

module ClientForPoslynx

  module MessageHandling

    def self.stream_data_extractor(stream)
      xml_extractor = XmlExtractor.new( stream )
      DataExtractor.new( xml_extractor )
    end

  end

end
