# coding: utf-8

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'client_for_poslynx'
require 'client_for_poslynx/experimental'
Dir[File.join( File.dirname(__FILE__), 'support', '**', '*.rb')].each do |script|
  require script
end
