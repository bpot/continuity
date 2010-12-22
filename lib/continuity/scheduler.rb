module Continuity
  class Scheduler
    def self.new_using_redis(redis)
      new(RedisBackend.new(redis))
    end

    def initialize(backend, frequency = 10)
      @frequency      = frequency
      @backend        = backend
      @next_schedule  = 0

      @jobs = {}
    end

    def every(period, &blk)
      @jobs[PeriodEntry.new(period)] = blk
    end

    def cron(cron_line, &blk)
      @jobs[CronEntry.new(cron_line)] = blk
    end
    
    def run
      now = Time.now.to_i
      return unless next_schedule <= now

      scheduled_up_to = @backend.lock_for_scheduling(now) do |previous_time|
        do_jobs(previous_time, now)
      end

      next_schedule = scheduled_up_to + @frequency
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
  end
end
