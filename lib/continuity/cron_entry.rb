module Continuity
  class CronEntry
    def initialize(s)
      cron_parts = s.split(" ")
      if cron_parts.size == 5
        cron_parts.unshift("0")
      elsif cron_parts.size != 6
        raise "Cron format invalid"
      end

      seconds, minutes, hours, dates, months, dayofweek = *cron_parts

      @seconds_bits  = get_bits(seconds,  60)
      @minutes_bits  = get_bits(minutes,  60)
      @hours_bits    = get_bits(hours,    60)
      @doms_bits     = get_bits(dates,    31, false)
      @months_bits   = get_bits(months,   12, false)
      @dows_bits     = get_bits(dayofweek, 7)
    end

    def at?(time)
      tst(@seconds_bits, time.sec)   &&
      tst(@minutes_bits, time.min)   &&
      tst(@hours_bits  , time.hour)  &&
      tst(@doms_bits   , time.mday)  &&
      tst(@months_bits , time.month) &&
      tst(@dows_bits   , time.wday)
    end

    private

    def get_bits(s, base, zero_indexed = true)
      bits = 0

      s.split(",").each do |r|
        interval, range = parse_range_and_interval(r, base, zero_indexed)

        range.step(interval) do |n| 
          bits |= 1 << n
        end
      end

      bits
    end

    def parse_range_and_interval(s, base, zero_indexed)
      # extract interval (if exists)
      if s.include?("/")
        s, interval = s.split("/")
      else
        interval = 1
      end

      if s == "*"
        if zero_indexed
          low = 0
          high = base - 1
        else
          low = 1
          high = base
        end
      elsif s.include?("-")
        low, high = s.split("-")
      else
        low = high = s
      end

      return interval.to_i, Range.new(low.to_i, high.to_i)
    end

    def tst(bits, n)
      (bits & (1 << n)) > 0
    end
  end
end
