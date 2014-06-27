require 'forwardable'

module Semaphoria
  class Client
    extend  Forwardable
    include Semaphoria::Calls

    attr_accessor :agent

    def_delegators :@agent, :host, :scheme

    def initialize(params={})
      self.agent = Semaphoria::Agent.new({
        :host   => params.fetch(:host),
        :scheme => params.fetch(:scheme, "http")
      })
    end
  end
end