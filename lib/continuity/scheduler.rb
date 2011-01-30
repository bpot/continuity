module Continuity
  class Scheduler
    def self.new_using_redis(redis, frequency = 10)
      new(RedisBackend.new(redis, frequency))
    end

    def initialize(backend, frequency = 10)
      @frequency      = frequency
      @backend        = backend
      @next_schedule  = 0
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

    def trigger_cbs(range)
      @on_schedule_cbs.each { |cb| cb.call(range) }
    end

    def run
      @scheduling_thread = Thread.new {
        loop do
          begin
            maybe_schedule
            sleep 1
          rescue Object
            # log this error
          end
        end
      }
    end

    def join
      @scheduling_thread.join
    end

    def maybe_schedule
      now = Time.now.to_i
      return false unless @next_schedule <= now

      range_scheduled = false
      scheduled_up_to = @backend.lock_for_scheduling(now) do |previous_time|
        range_scheduled = (previous_time+1)..now
        do_jobs(range_scheduled)
        trigger_cbs(range)
        yield range_scheduled
      end

      @next_schedule = scheduled_up_to + @frequency

      return range_scheduled
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
