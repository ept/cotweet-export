require 'rubygems'
require 'highline'
require 'json'
require 'eventmachine'
require 'deferrable_gratification'
require 'em-http'
require 'set'

DG.enhance! EM::HttpClient

$stdout.sync = true

%w{
  connection download_queue export
}.each do |filename|
  require File.join(File.dirname(__FILE__), 'cotweet', filename)
end

CoTweet::Export.run!
