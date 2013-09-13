module Continuity
  class Scheduler
    def self.new_using_redis(redis, args = {})
      frequency = args.delete(:frequency) || 10

      new(RedisBackend.new(redis, frequency), args)
    end

    def initialize(backend, args = {})
      @frequency      = args[:frequency] || 10
      @reentrant      = args[:reentrant] || true
      @entry_time     = args[:entry_time] || Time.now
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

    def run(check_frequency = 5)
      @scheduling_thread = Thread.new {
        loop do
          begin
            maybe_schedule
            sleep check_frequency
          rescue Object
            $stderr.print "--Error in Continuity Scheduler--\n"
            $stderr.print $!.backtrace.join("\n")
          end
        end
      }
    end

    def join
      @scheduling_thread.join
    end

    def maybe_schedule(now = Time.now.to_i)
      return false unless @next_schedule <= now

      range_scheduled = false
      scheduled_up_to = @backend.lock_for_scheduling(now) do |previous_time|
        range_start       = @reentrant ? previous_time : [previous_time, @entry_time.to_i].max
        range_end         = @reentrant ? now : [now, @entry_time.to_i].max
        range_scheduled   = (range_start+1)..range_end
        do_jobs(range_scheduled)
        trigger_cbs(range_scheduled)
        yield range_scheduled if block_given?
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
    private

    def trigger_cbs(range)
      @on_schedule_cbs.each { |cb| cb.call(range) }
    end
  end
end
