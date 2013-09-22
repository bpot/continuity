require 'helper'
require 'minitest/autorun'
require 'continuity'

include Continuity

NOW = Time.now.to_i
EPOCH = (NOW..(NOW + 1))
class SimpleBackend
  def each_epoch(&block)
    block.call(EPOCH)
  end
end

describe Scheduler do
  before do
    @backend = MiniTest::Mock.new
  end

  describe "#run" do
    before do
      @scheduler = Scheduler.new(SimpleBackend.new)
    end
    
    it "should do scheduled jobs" do
      range = nil
      @scheduler.cron("* * * * * *") do |r|
        range = r
      end

      @scheduler.run
      @scheduler.join
      assert range
    end

    it "should call #on_schedule blocks" do
      range = nil
      @scheduler.on_schedule do |r|
        range = r
      end

      @scheduler.run
      @scheduler.join
      assert range
    end
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
end
