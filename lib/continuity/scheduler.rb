module Continuity
  class Scheduler
    def self.new_using_redis(redis, args={})
      require 'continuity/redis_backend'

      discard_past = args.delete(:discard_past)

      new(RedisBackend.new(redis, args), :discard_past => discard_past)
    end

    def self.new_using_zookeeper(zookeepers, args={})
      require 'continuity/zk_backend'

      discard_past = args.delete(:discard_past)

      new(ZkBackend.new(zookeepers, args), :discard_past => discard_past)
    end

    attr_reader :backend, :discard_past

    def initialize(backend, args={})
      @backend          = backend
      @on_schedule_cbs  = []
      @discard_past     = args[:discard_past].nil? ? true : args[:discard_past]

      @jobs             = {}
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

          with_optionally_discarded_past(epoch) do |time|
            do_jobs(time)
          end

          trigger_cbs(epoch)
        end
      }
    end

    def join
      @scheduling_thread.join
    end

    def do_jobs(time)
      @jobs.each do |cron_entry, blk|
        if cron_entry.at?(time)
          blk[time]
        end
      end
    end

    private

    def with_optionally_discarded_past(epoch)
      now = Time.now

      epoch.map do |t|
        Time.at(t)
      end.select do |time|
        !discard_past || time > now
      end.each do |time|
        yield time
      end
    end

    def trigger_cbs(range)
      @on_schedule_cbs.each { |cb| cb.call(range) }
    end
  end
end
