require 'rubygems'
require 'bundler'
require 'simplecov'
SimpleCov.start
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'minitest'
require 'minitest/unit'
require 'minitest/pride'

$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'continuity'

class MiniTest::Unit::TestCase
end

def redis_clean
  redis = Redis.new(:thread_safe => true, :port => 16379)
  begin
    redis.flushall
  rescue Errno::ECONNREFUSED
    puts '***** Tests need an instance of redis running at 16379. `redis-server test/redis.conf` *****'
    exit
  end
  redis
end

MiniTest.autorun
