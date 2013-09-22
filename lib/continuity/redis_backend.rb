module Continuity
  class RedisBackend
    LOCK_KEY = "continuity_lock"
    LAST_SCHED_KEY = "continuity_scheduled_up_to"

    def initialize(redis, args={})
      @redis          = redis
      @lock_timeout   = args[:lock_timeout] || 30
      @frequency      = args[:frequency] || 10
      @next_schedule  = 0
    end

    # Yields the each time block which neds to be scheduled,
    # if a lock has been established
    def each_epoch(&block)
      loop do
        begin
          maybe_schedule(&block)
          sleep @frequency
        rescue Object
          $stderr.print "--Error in Continuity Scheduler--\n"
          $stderr.print $!.backtrace.join("\n")
        end
      end
    end

    def maybe_schedule(now=Time.now.to_i)
      return false unless @next_schedule <= now

      range_scheduled = false
      scheduled_up_to = lock_for_scheduling(now) do |previous_time|
        range_scheduled = (previous_time+1)..now
        yield range_scheduled if block_given? # replaces `do_jobs(range_scheduled); trigger_cbs(range_scheduled)`
      end

      @next_schedule = scheduled_up_to + @frequency

      return range_scheduled
    end

    def lock_for_scheduling(now)
      scheduled_up_to = @redis.get(LAST_SCHED_KEY).to_i

      # bootstrap
      if scheduled_up_to == 0
        lock(now) do

          # double check that someone else has bootstrapped
          # since we fetched the key
          scheduled_up_to = @redis.get(LAST_SCHED_KEY).to_i
          if scheduled_up_to == 0
            yield now - 1
            @redis.set(LAST_SCHED_KEY, now)

            return now
          else
            return scheduled_up_to
          end
        end

      end

      # this is tricky, we only want to attempt a lock
      # if there is a possibility we can schedule things.
      # BUT, once we attain a lock we need to make sure 
      # someone else hasn't already scheduled that period
      if (now - scheduled_up_to) >= @frequency
        lock(now) do
          scheduled_up_to = @redis.get(LAST_SCHED_KEY).to_i
          if (now - scheduled_up_to) >= @frequency
            # good we should still schedule
            yield scheduled_up_to
            @redis.set(LAST_SCHED_KEY, now)
            scheduled_up_to = now
          end
        end
      end

      scheduled_up_to
    end

    private
    # http://code.google.com/p/redis/wiki/SetnxCommand
    def lock(now)
      lock_expiration = now + @lock_timeout + 1 
      res = @redis.setnx(LOCK_KEY, lock_expiration)

      acquired_lock = false
      if res
        acquired_lock = true
        yield
      else
        current_expiration  = @redis.get(LOCK_KEY).to_i
        if current_expiration < now
          new_expiration = now + @lock_timeout + 1 
          if current_expiration == @redis.getset(LOCK_KEY, new_expiration).to_i
            acquired_lock = true
            yield
          end
        end
      end
    ensure
      if acquired_lock
        @redis.del(LOCK_KEY)
      end
    end
  end
end
