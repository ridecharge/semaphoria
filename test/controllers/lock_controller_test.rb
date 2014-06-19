require 'test_helper'

class LockControllerTest < ActionController::TestCase

  context "on GET for lock_status" do
    setup do
      @env=Environment.new(name: "trunk")
      @app=App.new(name: "foobar")
      @user=User.new(name: "bob")
    end

    should 'return true if there is an active lock' do
      @lock=Lock.create(environment: @env, app: @app, user: @user)
      get :lock_status, {environment: @env.name, app: @app.name}
      assert_response :success
      result={locked: true, at: @lock.created_at, by: @user.name}
      assert_equal result, JSON.parse(@response.body.to_s)
    end

    should 'return false if there is not an active lock' do
      get :lock_status, {environment: @env.name, app: @app.name}
      assert_response :success
      result={locked: false}
      assert_equal result, JSON.parse(@response.body.to_s)
    end

    should 'return false when all locks are inactive' do
      @lock=Lock.create(environment: @env, app: @app, user: @user)
      @lock.release!
      get :lock_status, {environment: @env.name, app: @app.name}
      assert_response :success
      assert_equal result, JSON.parse(@response.body.to_s)
    end

    should 'return an error without both app and env' do
      get :lock_status, {environment: "foobar"}
      assert_response :error
      get :lock_status, {app: "foobar"}
      assert_response :error
    end

    should 'return an error if there is no such thing' do
      get :lock_status, {environment: "foobusy", app: @app.name}
      assert_response :error
      result={error: "Invalid app/env"}
      assert_equal result, JSON.parse(@response.body.to_s)
    end
  end
end
