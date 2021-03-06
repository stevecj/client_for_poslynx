# coding: utf-8

require_relative 'message_handling/xml_extractor'
require_relative 'message_handling/data_extractor'
require_relative 'message_handling/stream_data_writer'
require_relative 'message_handling/xml_lines_buffer'

module ClientForPoslynx

  module MessageHandling

    def self.stream_data_reader(stream)
      xml_extractor = XmlExtractor.new( stream )
      DataExtractor.new( xml_extractor )
    end

    def self.stream_data_writer(stream)
      StreamDataWriter.new( stream )
    end

  end

end
