require 'test_helper'

class LockControllerTest < ActionController::TestCase
  setup do
    @env=Environment.create(name: "trunk")
    @app=App.create(name: "foobar")
    @user=User.create(name: "bob")
  end

  context "on GET for lock_status" do

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

  context "on POST to lock" do

    should 'return an error without app, env and user' do
      assert_raise ActionController::ParameterMissing do
        post :create, format: :json, environment: "foobar", user: "foobar"
      end
      assert_raise ActionController::ParameterMissing do
        post :create, format: :json, app: "foobar", user: "foobar"
      end
      assert_raise ActionController::ParameterMissing do
        post :create, format: :json, app: "foobar", environment: "foobar"
      end
    end

    should 'return an error if there is no such app or env' do
      post :create, format: :json, environment: "foobusy", app: @app.name, user: "foobar"
      assert_response :error
      result={"error" => "Invalid app/env"}
      assert_equal result, JSON.parse(@response.body.to_s)
    end

    should "create a user if it doesn't exist" do
      name="foobar_#{Time.now.to_s}"
      post :create, format: :json, environment: @env.name, app: @app.name, user: name
      assert_response :success
      assert_equal true, !User.where(:name => name).empty?
    end

    should "lock an app/env" do
      post :create, format: :json, environment: @env.name, app: @app.name, user: @user.name
      assert_response :success
      @lock = assigns(:lock)
      assert_not_nil @lock
      assert_equal @env, @lock.environment
      assert_equal @app, @lock.app
      assert_equal @user, @lock.user
      assert @lock.active?
    end

    should "force an override of an existing lock" do
      @old_lock=Lock.create(environment: @env, app: @app, user: @user)
      assert @old_lock.active?
      post :create, format: :json, environment: @env.name, app: @app.name, user: "foobar"
      assert_response :success
      @lock = assigns(:lock)
      assert_not_nil @lock
      assert_equal @env, @lock.environment
      assert_equal @app, @lock.app
      assert_equal "foobar", @lock.user.name
      assert @lock.active?
      assert !Lock.find(@old_lock.id).active?
    end
  end

  context "on PUT to lock" do
    should 'return an error without both app and env' do
      assert_raise ActionController::ParameterMissing do
        put :release, format: :json, environment: "foobar"
      end
      assert_raise ActionController::ParameterMissing do
        put :release, format: :json, app: "foobar"
      end
    end

    should 'return an error if there is no such thing' do
      put :release, format: :json, environment: "foobusy", app: @app.name
      assert_response :error
      result={"error" => "Invalid app/env"}
      assert_equal result, JSON.parse(@response.body.to_s)
    end

    should "release a lock" do
      @old_lock=Lock.create(environment: @env, app: @app, user: @user)
      put :release, format: :json, environment: @env.name, app: @app.name
      assert_response :success
      assert !Lock.find(@old_lock.id).active?
    end
  end
end
