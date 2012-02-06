require 'rubygems'
require 'bundler/setup'
require 'highline'
require 'json'
require 'andand'
require 'eventmachine'
require 'deferrable_gratification'
require 'em-http'
require 'set'

DG.enhance! EM::HttpClient

%w{
  connection download_queue export
}.each do |filename|
  require File.join(File.dirname(__FILE__), 'cotweet', filename)
end
