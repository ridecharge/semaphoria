require 'httparty'
require 'addressable/uri'
require 'json'

module Semaphoria
  class Agent

    PermittedVerbs = [:get, :put, :post, :delete]

    attr_accessor :host, :scheme

    def initialize(params={})
      self.host   = params.fetch(:host)
      self.scheme = params.fetch(:scheme)
    end

    def fetch(params={})
      verb   = params.fetch(:verb, :get)
      raise ArgumentError, "http verb must be in #{PermittedVerbs}" unless PermittedVerbs.include? verb.to_sym
      action = params.fetch(:action)
      fields = params.fetch(:fields, {})
      scheme = self.scheme
      host   = self.host
      resp   = Semaphoria::Response.new
      uri    = Addressable::URI.new({
        :scheme => scheme,
        :host   => host,
        :path   => action
      })
      options = {:headers => {'Content-Type' => 'application/json', 'Accept' => 'application/json'}}

      unless fields.empty?
        if verb == :get
          options.merge!({ :query => fields })
        else
          options.merge!({ :body => fields.to_json })
        end
      end

      begin
        http           = verb == :get ? HTTParty.get(uri, options) : HTTParty.send(verb, uri, options)
        resp.status    = http.code
        resp.response  = JSON.parse(http.body) unless http.body.strip.empty?
        resp.message   = http.message
        resp.timestamp = Time.now.utc
      rescue OpenSSL::SSL::SSLError
        resp.errors << "Unable to communicate with #{uri.scheme}://#{uri.host}/ over SSL"
      rescue Errno::ECONNREFUSED
        resp.errors << "Connection to #{uri.scheme}://#{uri.host}/ was refused"
      rescue Errno::ETIMEDOUT
        resp.errors << "Timed out connecting to #{uri.scheme}://#{uri.host}/"
      rescue Errno::EHOSTDOWN
        resp.errors << "The host at #{uri.scheme}://#{uri.host}/ is not responding to requests"
      rescue Errno::EHOSTUNREACH
        resp.errors << "Possible network issue communicating with #{uri.scheme}://#{uri.host}/"
      rescue SocketError
        resp.errors << "Couldn't make sense of the host destination #{uri.scheme}://#{uri.host}/"
      rescue JSON::ParserError
        resp.errors << "The host at #{uri.scheme}://#{uri.host}/ returned a non-JSON response"
      end
      resp
    end
  end
end