module Semaphoria 
  class Response
    
    attr_accessor :status, :response, :modified_response, :message, :timestamp, :errors

    def initialize(params={})
      self.status    = params[:status]
      self.response  = params[:response]
      self.modified_response  = params[:modified_response]
      self.message   = params[:message]
      self.timestamp = params[:timestamp] || Time.now.utc
      self.errors    = []
    end

    def locked?
      response["locked"]
    end

    def locked_at
      response["at"]
    end

    def locked_by
      response["by"]
    end

    def successful?
      !(/^2\d\d$/.match(status.to_s).nil?) && errors.empty?
    end

  end
end