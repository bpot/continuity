require 'helper'
require 'minitest/autorun'
require 'continuity'

describe Continuity::RedisBackend do
  before do
    @redis = Redis.new(:thread_safe => true, :port => 16379)
    begin
      @redis.flushall
    rescue Errno::ECONNREFUSED
      puts '***** Tests need an instance of redis running at 16379. `redis-service test/redis.conf` *****'
      exit
    end

    @rb = Continuity::RedisBackend.new(@redis, 10, 30)
  end

  describe "bootstrapping" do
    it "should set current time as the last scheduled at time" do
      now = Time.now.to_i
      @rb.lock_for_scheduling(now) {}
      last_scheduled_at = @rb.lock_for_scheduling(now+1) {}
      last_scheduled_at.must_equal now
    end

    it "should not yield" do
      yielded = false

      now = Time.now.to_i
      @rb.lock_for_scheduling(now) { yielded = true }

      yielded.must_equal false
    end
  end

  describe "trying to lock before scheduling period is over" do
    before do
      now = Time.now.to_i
      @rb.lock_for_scheduling(now) {}
    end

    it "should not yield" do
      now = Time.now.to_i
      @rb.lock_for_scheduling(now) {}

      yielded = false

      @rb.lock_for_scheduling(now+5) { yielded = true }

      yielded.must_equal false
    end
  end

  describe "trying to lock while another client holds to lock" do
    it "should not yield" do
      first_yields = false
      second_yields = false
      now = Time.now.to_i
      @rb.lock_for_scheduling(now) {}

      @rb.lock_for_scheduling(now+30) do
        first_yields = true
        20.times do
          @rb.lock_for_scheduling(now+35) do
            second_yields = true
          end
        end
      end

      first_yields.must_equal true
      second_yields.must_equal false
    end
  end

  describe "locking after waiting period is up" do
    it "should yield" do
      now = Time.now.to_i
      @rb.lock_for_scheduling(now) {}

      yielded = false
      @rb.lock_for_scheduling(now+15) { yielded = true }
      yielded.must_equal true
    end

    it "should yield last scheduled time" do
      now = Time.now.to_i
      @rb.lock_for_scheduling(now) {}

      yielded = false
      @rb.lock_for_scheduling(now+11) { |t| 
        t.must_equal now
        yielded = true 
      }
      yielded.must_equal true
    end

    it "should continue to yield as time goes on" do
      yielded_count = 0
      now = Time.now.to_i
      @rb.lock_for_scheduling(now) {}

      10.times do |n|
        @rb.lock_for_scheduling(now+((n+1)*30)) do
          yielded_count += 1
        end
      end

      yielded_count.must_equal 10
    end
  end
end
