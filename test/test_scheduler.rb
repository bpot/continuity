require 'helper'
require 'minitest/autorun'
require 'continuity'

include Continuity

describe Scheduler do
  before do
    @backend = MiniTest::Mock.new
  end

  describe "do_jobs" do
    describe "cron job '0 0 * * * *'" do
      before do
        @scheduler = Scheduler.new(@backend)
      end

      it "should run every hour" do
        job_run = false
        @scheduler.cron("0 0 * * * *") do
          job_run = true
        end
        
        time = Time.parse("2010-12-20 08:00:00").to_i
        @scheduler.do_jobs(time..time)

        job_run.must_equal true
      end
    end
  end

  describe "maybe schedule" do
    before do
      @scheduler = Scheduler.new_using_redis(redis_clean)
    end

    it "should call a passed in block with the range scheduled" do
      range = nil
      @scheduler.maybe_schedule do |r|
        range = r
      end
      assert range
    end

    it "should call #on_schedule blocks" do
      range = nil
      @scheduler.on_schedule do |r|
        range = r
      end

      @scheduler.maybe_schedule
      assert range
    end
  end
end
