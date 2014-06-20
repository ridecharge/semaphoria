class LockController < ApplicationController

  skip_before_filter :verify_authenticity_token

  def lock_status
    params.require(:app)
    params.require(:environment)
    if get_app_env
      lock=Lock.where(:app => @app, :environment => @env, :active => true).first
      if lock.nil?
        render :json => {locked: false}
      else
        render :json => {locked: true, at: lock.created_at, by: lock.user.name}
      end
    end
  end

  def create
    params.require(:app)
    params.require(:environment)
    params.require(:user)
    if get_app_env
      @user = User.find_or_create_by(:name => params[:user])
      release_all_locks
      @lock = Lock.create(:user => @user, :environment => @env, :app => @app)
      head 200
    end
  end

  def release
    params.require(:app)
    params.require(:environment)
    if get_app_env
      release_all_locks
      head 200
    end
  end

  private
  def get_app_env
    @app=App.find_by_name(params[:app])
    @env=Environment.find_by_name(params[:environment])
    not_found=(@app.nil? or @env.nil?)
    render :json => {error: "Invalid app/env"}, :status => 500 if not_found
    return !not_found
  end

  def release_all_locks
    Lock.where(:app => @app, :environment => @env, :active => true).each do |lock|
      lock.release!
    end
  end

end
