# coding: utf-8

require "client_for_poslynx/version"
require "client_for_poslynx/data"
require "client_for_poslynx/message_handling"
require "client_for_poslynx/bit_sequence"
require "client_for_poslynx/signature_image"
require "client_for_poslynx/net"

module ClientForPoslynx

  class Error < StandardError ; end
  class InvalidXmlError < Error ; end
  class InvalidXmlContentError < Error ; end

end
