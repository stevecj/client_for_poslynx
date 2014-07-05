# coding: utf-8

require "client_for_poslynx/version"
require "client_for_poslynx/data"

module ClientForPoslynx

  class Error < StandardError ; end
  class InvalidXmlError < Error ; end
  class InvalidXmlContentError < Error ; end

end
