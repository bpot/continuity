module Continuity
  class CronFormatError < StandardError; end
  class CronEntry
    def initialize(entry)
      @entry = entry

      cron_parts = @entry.split(" ")
      if cron_parts.size == 5
        cron_parts.unshift("0")
      elsif cron_parts.size != 6
        raise CronFormatError, "Cron entry is invalid: #{@entry}"
      end

      seconds, minutes, hours, dates, months, dayofweek = *cron_parts

      @seconds_bits  = get_bits(seconds,  (0..60))
      @minutes_bits  = get_bits(minutes,  (0..60))
      @hours_bits    = get_bits(hours,    (0..60))
      @doms_bits     = get_bits(dates,    (1..31))
      @months_bits   = get_bits(months,   (1..12))
      @dows_bits     = get_bits(dayofweek,(0..7))
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

    def get_bits(s, valid_range)
      bits = 0

      s.split(",").each do |r|
        interval, range = parse_range_and_interval(r, valid_range)

        range.step(interval) do |n| 
          bits |= 1 << n
        end
      end

      bits
    end

    def parse_range_and_interval(s, valid_range)
      # extract interval (if exists)
      if s.include?("/")
        s, interval = s.split("/")
        interval    = cast_and_validate_integer(interval, valid_range)
      else
        interval = 1
      end

      # determine trigger range
      if s == "*"
        trigger_range = valid_range
      elsif s.include?("-")
        low, high = s.split("-")

        low   = cast_and_validate_integer(low, valid_range)
        high  = cast_and_validate_integer(high, valid_range)
        trigger_range = (low..high)
      else
        s = cast_and_validate_integer(s, valid_range)
        trigger_range = (s..s)
      end

      return interval, trigger_range
    end

    def tst(bits, n)
      (bits & (1 << n)) > 0
    end

    def cast_and_validate_integer(i, valid_range)
      if i.match(/\d+/)
        i = i.to_i

        if valid_range.include?(i)
          return i
        end
      end

      raise CronFormatError, "Cron entry is invalid: #{@entry} (#{i} outside of #{valid_range}"
    end
  end
end
