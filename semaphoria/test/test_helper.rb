require 'rubygems'
require 'bundler/setup'
require 'webmock'
require 'vcr'
require 'semaphoria'
default_options = { :match_requests_on => [:method, :uri], :allow_playback_repeats => true}
VCR.configure do |c|
  c.cassette_library_dir = File.expand_path(File.dirname(__FILE__) +'/vcr_cassettes')
  c.allow_http_connections_when_no_cassette = false
  c.default_cassette_options = default_options
  c.hook_into :webmock 
  c.ignore_hosts 'codeclimate.com'
end
