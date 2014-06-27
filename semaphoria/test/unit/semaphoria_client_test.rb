require 'test_helper'
require 'minitest/autorun'
class SemaphoriaClientTest < Minitest::Test

  def setup
    @client = Semaphoria::Client.new(:host => "semaphoria.herokuapp.com", :scheme => "http")
  end

  def test_able_to_get_lock_status
    VCR.use_cassette("retrieve_lock_status_success_not_locked") do
      response=@client.lock_status("god", "automate")
      assert response.successful?
      assert !response.locked?
    end
    VCR.use_cassette("retrieve_lock_status_success_locked") do
      response=@client.lock_status("god", "automate")
      assert response.successful?
      assert response.locked?
    end
    VCR.use_cassette("retrieve_lock_status_fail") do
      response=@client.lock_status("foobar", "automate")
      assert !response.successful?
    end
  end

  def test_locking
    VCR.use_cassette("do_lock") do
      response=@client.lock("god", "automate", "foobar")
      assert response.successful?
      response=@client.lock_status("god", "automate")
      assert response.successful?
      assert response.locked?
      assert_equal "foobar", response.locked_by
      assert_equal "2014-06-27T20:55:02.371Z", response.locked_at
    end
  end

  def test_unlocking
    VCR.use_cassette("do_unlock") do
      response=@client.unlock("god", "automate")
      assert response.successful?
      response=@client.lock_status("god", "automate")
      assert response.successful?
      assert !response.locked?
    end
  end

  def test_function_when_host_unreachable
    VCR.use_cassette("host_unreachable") do
      @client = Semaphoria::Client.new(:host => "semaphorifoobar.herokufoobar.com", :scheme => "http")
      response = @client.lock_status("foobar", "barfoo")
      assert !response.successful?
    end
  end
end