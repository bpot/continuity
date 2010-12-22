require 'helper'
require 'minitest/autorun'
require 'continuity'

include Continuity

def build_scheduler
  redis = Redis.new(:port => 16379)
  scheduler = Continuity::Scheduler.new_using_redis(redis)
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
    redis = Redis.new(:port => 16379)
    redis.flushall
  end

  it "should schedule a continuous range" do
    @workers = []
    last_scheduled = nil

    WORKER_COUNT.times do

      @workers << Thread.new do
        s = build_scheduler
        
        loop do
          sleep rand(5)
          range = s.run

          if range
            MUTEX.synchronize do
              if last_scheduled.nil?
                last_scheduled = range.last
              else
                (last_scheduled + 1).must_equal range.first
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
