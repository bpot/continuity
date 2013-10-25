require 'rubygems'
require 'bundler'
require 'simplecov'
require 'pry'
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

def redis_test_client
  if ENV['TRAVIS'] && ENV['CI']
    # Use default port for travis ci (we have not control)
    redis = Redis.new(:thread_safe => true)
  else
    redis = Redis.new(:thread_safe => true, :port => 16379)
  end
end

def redis_clean
  redis = redis_test_client
  begin
    redis.flushall
  rescue Errno::ECONNREFUSED
    puts '***** Tests need an instance of redis running at 16379. `redis-server test/redis.conf` *****'
    exit
  end
  redis
end

MiniTest.autorun
