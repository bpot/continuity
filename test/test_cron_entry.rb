require 'helper'
require 'minitest/autorun'
require 'continuity'

include Continuity

describe CronEntry do
  describe "0 * * * * * (every minute)" do
    before do
      @ce = CronEntry.new("0 * * * * *")
    end

    it "should run at 2010-12-20 00:00:00" do
      @ce.at?(Time.parse("2010-12-20 00:00:00")).must_equal true
    end

    it "should not run at 2010-12-20 00:00:01" do
      @ce.at?(Time.parse("2010-12-20 00:00:01")).must_equal false
    end

    it "should run 60 times in a one hour period" do
      count = 0
      start = Time.parse("2010-12-20 00:00:00").to_i
      start.upto(start + 3599) do |t|
        count += 1 if @ce.at?(Time.at(t))
      end
      count.must_equal 60
    end
  end

  describe "0 1 * * * * (every hour)" do
    before do
      @ce = CronEntry.new("0 1 * * * *")
    end

    it "should run at 2010-12-20 01:01:00" do
      @ce.at?(Time.parse("2010-12-20 01:01:00")).must_equal true
    end

    it "should not run at 2010-12-20 00:01:01" do
      @ce.at?(Time.parse("2010-12-20 00:01:01")).must_equal false
    end

    it "should run 24 times in a one day period" do
      count = 0
      start = Time.parse("2010-12-20 00:01:00").to_i
      start.upto(start + 86399) do |t|
        count += 1 if @ce.at?(Time.at(t))
      end
      count.must_equal 24 
    end
  end

  describe "0 0 0 1 * * (first of the month)" do
    before do
      @ce = CronEntry.new("0 0 0 1 * *")
    end

    it "should run at 2010-12-01 00:00:00" do
      @ce.at?(Time.parse("2010-12-01 00:00:00")).must_equal true
    end

    it "should run at 2010-08-01 00:00:00" do
      @ce.at?(Time.parse("2010-08-01 00:00:00")).must_equal true
    end

    it "should not run at 2010-12-02 00:00:00" do
      @ce.at?(Time.parse("2010-12-02 00:00:00")).must_equal false
    end

    it "should not run at 2010-12-01 01:00:00" do
      @ce.at?(Time.parse("2010-12-01 01:00:00")).must_equal false
    end

    it "should run 12 times in a year" do
      count = 0
      start = Time.parse("2010-01-01 00:00:00").to_i
      year_end = Time.parse("2010-12-31 23:59:59").to_i
      start.step(year_end, 3600) do |t|
        if @ce.at?(Time.at(t))
          count += 1 
        end
      end
      count.must_equal 12 
    end
  end

  describe "0 0 0 1 1,4,7,10 * (quarterly months)" do
    before do
      @ce = CronEntry.new("0 0 0 1 1,4,7,10 *")
    end

    it "should run at 2010-04-01 00:00:00" do
      @ce.at?(Time.parse("2010-04-01 00:00:00")).must_equal true
    end

    it "should not run at 2010-03-01 00:00:00" do
      @ce.at?(Time.parse("2010-03-01 00:00:00")).must_equal false
    end

    it "should run 4 times in a year" do
      count = 0
      start = Time.parse("2010-01-01 00:00:00").to_i
      year_end = Time.parse("2010-12-31 23:59:59").to_i
      start.step(year_end, 3600) do |t|
        if @ce.at?(Time.at(t))
          count += 1 
        end
      end
      count.must_equal 4
    end
  end

  describe "0 0 7 * * 0 (sunday @ 7am)" do
    before do
      @ce = CronEntry.new("0 0 7 * * 0")
    end

    it "should run at 2010-12-19 07:00:00" do
      @ce.at?(Time.parse("2010-12-19 07:00:00")).must_equal true
    end

    it "should run at 2010-12-26 07:00:00" do
      @ce.at?(Time.parse("2010-12-26 07:00:00")).must_equal true
    end

    it "should not run at 2010-12-27 07:00:00" do
      @ce.at?(Time.parse("2010-12-27 07:00:00")).must_equal false
    end

    it "should not run at 2010-12-26 06:00:00" do
      @ce.at?(Time.parse("2010-12-26 06:00:00")).must_equal false
    end
  end

  describe "ranges w/intervals" do
    before do
      # 10 * 20 * 3 = 600 times in a day
      @ce = CronEntry.new("0-9/2,20-39/4 40-59/1 2,4,8 * * *")
    end

    it "should run at 2010-12-20 04:40:06" do
      @ce.at?(Time.parse("2010-12-20 04:40:06")).must_equal true
    end

    it "should run at 2010-12-20 02:50:24" do
      @ce.at?(Time.parse("2010-12-20 02:50:24")).must_equal true
    end

    it "should not run at 2010-12-20 03:50:22" do
      @ce.at?(Time.parse("2010-12-20 03:50:22")).must_equal false
    end

    it "should run 600 times in a day" do
      count = 0
      start = Time.parse("2010-12-20 02:40:09").to_i
      start.upto(start + 86399) do |t|
        if @ce.at?(Time.at(t))
          count += 1
        end
      end
      count.must_equal 600
    end
  end
end
