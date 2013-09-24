module Continuity
  class Scheduler
    def self.new_using_redis(redis, args={})
      require 'continuity/redis_backend'

      new(RedisBackend.new(redis, args))
    end

    def self.new_using_zookeeper(zookeepers, args={})
      require 'continuity/zk_backend'

      new(ZkBackend.new(zookeepers, args))
    end

    attr_reader :backend

    def initialize(backend)
      @backend        = backend
      @on_schedule_cbs = []

      @jobs = {}
    end

    def every(period, &blk)
      @jobs[PeriodicEntry.new(period)] = blk
    end

    def cron(cron_line, &blk)
      @jobs[CronEntry.new(cron_line)] = blk
    end

    def on_schedule(&block)
      @on_schedule_cbs << block
    end

    def run
      @scheduling_thread = Thread.new {
        @backend.each_epoch do |epoch|
          do_jobs(epoch)
          trigger_cbs(epoch)
        end
      }
    end

    def join
      @scheduling_thread.join
    end

    def do_jobs(time_range)
      time_range.each do |t|
        time = Time.at(t)
        @jobs.each do |cron_entry, blk|
          if cron_entry.at?(time)
            blk[time]
          end
        end
      end
    end
    private

    def trigger_cbs(range)
      @on_schedule_cbs.each { |cb| cb.call(range) }
    end
  end
end
