module Continuity
  class RedisBackend
    LOCK_KEY = "continuity_lock"
    LAST_SCHED_KEY = "continuity_scheduled_up_to"

    def initialize(redis, frequency = 10, lock_timeout = 30)
      @redis        = redis
      @lock_timeout = lock_timeout
      @frequency    = frequency
    end

    def lock_for_scheduling(now)
      scheduled_up_to = @redis.get(LAST_SCHED_KEY).to_i

      # bootstrap
      if scheduled_up_to == 0
        lock do
          @redis.set(LAST_SCHED_KEY, now)
        end

        return now
      end

      # this is tricky, we only want to attempt a lock
      # if there is a possibility we can schedule things.
      # BUT, once we attain a lock we need to make sure 
      # someone else hasn't already scheduled that period
      if (now - scheduled_up_to) >= @frequency
        lock do
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
    def lock
      lock_expiration = Time.now.to_i + @lock_timeout + 1 
      res = @redis.setnx(LOCK_KEY, lock_expiration)

      yielded = false
      if res
        yield
        yielded = true
      else
        current_expiration  = @redis.get(LOCK_KEY).to_i
        now = Time.now.to_i
        if current_expiration < now
          new_expiration = now + @lock_timeout + 1 
          if current_expiration == @redis.getset(LOCK_KEY, new_expiration).to_i
            yield
            yielded = true
          end
        end
      end

      if yielded
        @redis.del(LOCK_KEY)
      end
    end
  end
end
