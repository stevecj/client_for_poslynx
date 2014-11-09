# coding: utf-8

require 'nokogiri'

module ClientForPoslynx
  module Data

    class PropertiesXmlParser
      def self.parse(root_element_name, source_xml)
        new( root_element_name ).parse( source_xml )
      end

      attr_reader :root_element_name

      def initialize(root_element_name)
        @root_element_name = root_element_name
      end
    end

  end
end
