require 'helper'
require 'minitest/autorun'
require 'continuity'

include Continuity

describe PeriodicEntry do
  describe "10s" do
    before do
      @pe = PeriodicEntry.new("10s")
    end

    it "should trigger at Time.at(10)" do
      assert @pe.at?(Time.at(10))
    end

    it "should trigger 6 times in a minute" do
      times = 0

      time = Time.parse("2010-12-21 00:01:00").to_i
      time.upto(time + 59) do |n|
        times += 1 if @pe.at?(Time.at(n))
      end

      times.must_equal 6
    end
  end

  describe "1m" do
    before do
      @pe = PeriodicEntry.new("1m")
    end

    it "should trigger on the minute" do
      time = Time.parse("2010-12-21 00:01:00").to_i

      assert @pe.at?(time)
    end

    it "should trigger 60 times in a hour" do
      times = 0

      time = Time.parse("2010-12-21 00:00:00").to_i
      time.upto(time + 3599) do |n|
        times += 1 if @pe.at?(Time.at(n))
      end

      times.must_equal 60
    end
  end

  describe "2h" do
    before do
      @pe = PeriodicEntry.new("2h")
    end

    it "should trigger at 2am" do
      time = Time.parse("2010-12-21 02:00:00").to_i

      assert @pe.at?(time)
    end

    it "should trigger 12 times in a 24hour period" do
      times = 0

      time = Time.parse("2010-12-21 00:00:00").to_i
      time.upto(time + 86399) do |n|
        times += 1 if @pe.at?(Time.at(n))
      end

      times.must_equal 12
    end
  end

  describe "2d" do
    before do
      @pe = PeriodicEntry.new("2d")
    end

    it "should trigger 5 times in a 10day period" do
      times = 0

      time = Time.parse("2010-12-21 00:00:00").to_i
      time.upto(time + (86400 * 10) - 1) do |n|
        times += 1 if @pe.at?(Time.at(n))
      end

      times.must_equal 5 
    end
  end

  describe "1w" do
    before do
      @pe = PeriodicEntry.new("1w")
    end

    it "should trigger 4 times in 28 days" do
      times = 0

      time = Time.parse("2010-12-01 00:00:00").to_i
      time_end = Time.parse("2010-12-27 23:59:59").to_i
      time.upto(time_end) do |n|
        times += 1 if @pe.at?(Time.at(n))
      end

      times.must_equal 4 
    end
  end
end
