require 'helper'
require 'minitest/autorun'
require 'continuity'

include Continuity

def build_scheduler
  scheduler = Continuity::Scheduler.new_using_redis(redis_test_client)
  scheduler.cron("*/10 * * * * *") do
  end

  scheduler.every("1m") do
  end

  scheduler
end

WORKER_COUNT = 100
MUTEX        = Mutex.new
TEST_LENGTH  = 60

describe "simulation" do
  before do
    redis_test_client.flushall
  end

  it "should schedule a continuous range" do
    @workers = []
    last_scheduled = nil

    WORKER_COUNT.times do

      @workers << Thread.new do
        s = build_scheduler
        
        loop do
          sleep rand(5)
          range = s.backend.maybe_schedule

          if range
            MUTEX.synchronize do
              if last_scheduled.nil?
                last_scheduled = range.last
              else
                assert_equal (last_scheduled + 1), range.first
                last_scheduled = range.last
              end
            end
          end
        end

      end

    end

    sleep TEST_LENGTH
    @workers.each { |w| w.terminate }
    assert last_scheduled > Time.now.to_i - 20 
  end
end
