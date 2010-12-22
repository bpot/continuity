require 'continuity'

redis = Redis.new(:port => 16379)
scheduler = Continuity::Scheduler.new_using_redis(redis)

scheduler.cron("*/10 * * * * *") do
  print "10s schedulage on #{$$}\n"
end

scheduler.every("1m") do
  print "1m schedulage on #{$$}\n"
end

loop do
  sleep rand(5)
  scheduler.run
end
