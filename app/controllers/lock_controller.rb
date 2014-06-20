class LockController < ApplicationController

  def lock_status
    params.require(:app)
    params.require(:environment)
    respond_to do |format| 
      format.json do
        @app=App.find_by_name(params[:app])
        @env=Environment.find_by_name(params[:environment])
        if @app.nil? or @env.nil?
          render :json => {error: "Invalid app/env"}, :status => 500
        else
          lock=Lock.where(:app => @app, :environment => @env, :active => true).first
          if lock.nil?
            render :json => {locked: false}
          else
            render :json => {locked: true, at: lock.created_at, by: lock.user.name}
          end
        end
      end
    end
  end

end
