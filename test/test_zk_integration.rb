require 'helper'
require 'minitest/autorun'
require 'continuity'
require 'continuity/zk_backend'

include Continuity

ZK_CONN         = "localhost:2181"
ZK_KEY          = "/_continuity_scheduled_up_to"
ZK_WORKER_COUNT = 20
ZK_TEST_LENGTH  = 39

describe "zk_connection" do
  it "works" do
    zk = ZK.new(ZK_CONN)
    begin
      zk.rm_rf("/foo")
    rescue ZK::Exceptions::NoNode
    end
    zk.create("/foo", "bar")

    assert "bar" == zk.get("/foo").first
  end
end

describe "simulation" do
  it "should schedule" do
    @workers = []
    accumulator = 0
    mutex = Mutex.new
    failover = true
    ZK.open(ZK_CONN) do |zk|
      begin
        zk.delete(ZK_KEY)
      rescue ZK::Exceptions::NoNode
      end
      begin
        zk.rm_rf('/_zkelection')
      rescue ZK::Exceptions::NoNode
      end
    end

    ZK_WORKER_COUNT.times do
      @workers << Thread.new do
        begin
          scheduler = Continuity::Scheduler.new_using_zookeeper(ZK_CONN, :frequency => 1, :zk_key => ZK_KEY)
          scheduler.cron("*/10 * * * * *") do
            if failover
              failover = false
              raise "Failing over to another thread"
            end

            mutex.synchronize do
              accumulator += 1
            end
          end

          scheduler.run
          scheduler.join
        rescue
          raise unless $!.message =! /Failing over/
        end
      end
    end

    sleep ZK_TEST_LENGTH
    @workers.each { |w| w.terminate }
    assert accumulator == (ZK_TEST_LENGTH / 10) + 1
  end
end
