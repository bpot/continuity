require 'helper'
require 'minitest/autorun'
require 'continuity'

describe Continuity::RedisBackend do
  before do
    @rb = Continuity::RedisBackend.new(redis_clean, 10, 30)
  end

  describe "bootstrapping" do
    it "should set current time as the last scheduled at time" do
      now = Time.now.to_i
      @rb.lock_for_scheduling(now) {}
      last_scheduled_at = @rb.lock_for_scheduling(now+1) {}
      last_scheduled_at.must_equal now
    end

    it "should yield" do
      yielded = false

      now = Time.now.to_i
      @rb.lock_for_scheduling(now) { yielded = true }

      yielded.must_equal true
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

  describe "throwing exception in the block given to lock" do
    it "should release lock" do
      now = Time.now.to_i
      @rb.lock_for_scheduling(now) {}

      begin
        @rb.lock_for_scheduling(now+30) do
          raise StandardError
        end
      rescue
      end
      
      acquired_lock = false
      @rb.lock_for_scheduling(now+30) do
        acquired_lock = true
      end

      acquired_lock.must_equal true
    end
  end

  describe "expired lock" do
    it "should be acquireable" do
      now = Time.now.to_i
      @rb.lock_for_scheduling(now) {}
      
      acquired_lock_early = false
      acquired_lock = false

      @rb.lock_for_scheduling(now+30) do
        @rb.lock_for_scheduling(now+22) do
          acquired_lock_early = true
        end
        @rb.lock_for_scheduling(now+62) do
          acquired_lock = true
        end
      end

      acquired_lock.must_equal true
      acquired_lock_early.must_equal false
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
