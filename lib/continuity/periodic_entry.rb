module Continuity
  class PeriodicEntry
    PERIODS = {
      "s" => 1,
      "m" => 60,
      "h" => 3600,
      "d" => 86400,
      "w" => 86400*7
    }

    def initialize(s)
      matches = s.match(/(\d+)([smhdw])/)
      raise "Unable to parse period: #{s}" if matches.nil?

      @period = matches[1].to_i * PERIODS[matches[2]]
    end

    def at?(time)
      time.to_i % @period == 0
    end
  end
end
