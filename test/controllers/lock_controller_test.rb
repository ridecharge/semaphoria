require 'test_helper'

class LockControllerTest < ActionController::TestCase

  context "on GET for lock_status" do
    setup do
      @env=Environment.create(name: "trunk")
      @app=App.create(name: "foobar")
      @user=User.create(name: "bob")
    end

    should 'return true if there is an active lock' do
      @lock=Lock.create(environment: @env, app: @app, user: @user)
      get :lock_status, format: :json, environment: @env.name, app: @app.name
      assert_response :success
      result={"locked" => true, "at" => @lock.created_at, "by" => @user.name}.to_json
      assert_equal JSON.parse(result), JSON.parse(@response.body.to_s)
    end

    should 'return false if there is not an active lock' do
      get :lock_status, format: :json, environment: @env.name, app: @app.name
      assert_response :success
      result={"locked" => false}
      assert_equal result, JSON.parse(@response.body.to_s)
    end

    should 'return false when all locks are inactive' do
      @lock=Lock.create(environment: @env, app: @app, user: @user)
      @lock.release!
      get :lock_status, format: :json, environment: @env.name, app: @app.name
      assert_response :success
      result={"locked" => false}
      assert_equal result, JSON.parse(@response.body.to_s)
    end

    should 'return an error without both app and env' do
      assert_raise ActionController::ParameterMissing do
        get :lock_status, format: :json, environment: "foobar"
      end
      assert_raise ActionController::ParameterMissing do 
        get :lock_status, format: :json, app: "foobar"
      end
    end

    should 'return an error if there is no such thing' do
      get :lock_status, format: :json, environment: "foobusy", app: @app.name
      assert_response :error
      result={"error" => "Invalid app/env"}
      assert_equal result, JSON.parse(@response.body.to_s)
    end
  end
end
