# Continuity [![Build Status](https://travis-ci.org/bpot/continuity.png?branch=master)](https://travis-ci.org/bpot/continuity) [![Code Climate](https://codeclimate.com/github/bpot/continuity.png)](https://codeclimate.com/github/bpot/continuity)

NOTE: this has a decent amount of test coverage, but has yet to be tested in any kind of production environment. I hope to do some more real-worldish testing soon.

Allows you to share scheduling duties across any number of workers. Unlike other solutions (clockwork/rufus-scheduler) it doesn't introduce a single point of failure rely by relying on a single, always running scheduling process.  Workers use Redis to coordinate scheduling duties.  The scheduler will never miss a job, even if all workers are shut down for a period of time it will pick up from where it left off

Continuity only runs one job at a time, so your tasks should create jobs in Resque, DJ, etc and not actually do the heavy lifting themselves.

Redis could conceivably be replaced by any consistent datastore.

## Install

You need to install both the `continuity` gem and the datastore interface gem (currently either
`redis` or `zk`).

``` ruby
gem 'redis'   # For Continuity::Scheduler::new_using_redis
gem 'zk'      # For Continuity::Scheduler::new_using_zookeeper

gem 'continuity'
```

## Example
  
``` ruby
scheduler = Continuity::Scheduler.new_using_redis(redis_handle)
# or
scheduler = Continuity::Scheduler.new_using_zookeeper("zk1.domain.com:2181,zk2.domain.com:2181,zk3.domain.com:2181")

scheduler.every('10s') do
  Resque.enqueue(PeriodicJob)
end

scheduler.cron('0 0 * * * *') do
  Resque.enqueue(DailyJob)
end

scheduler.cron('0 * * * *') do
  Resque.enqueue(DailyJob)
end

scheduler_thread = scheduler.run
scheduler.join # if you want to execute the scheduler in the current thread
```

## Cron

* Supports a sixth field at the front for seconds. 
* It doesn't support month/day names, use the numeral.  
* In many cron implementations entries specifying the day of the month and day of the week (i.e. "0 0 11 1,5 * mon") have a special meaning, this is not supported.

## On Schedule Hook

``` ruby
scheduler.on_schedule do |range|
  delayed_jobs = $redis.zrangebyscore(:delayed_jobs, range.first, range.last)
  delayed_jobs.each do |job|
    do_it(job)
  end
end
```

## Dealing with the past

If all the schedulers go down, jobs which would have been scheduled during the down-time will not be re-scheduled.
You can enable scheduling jobs in the past by setting `discard_past` when you create the scheduler;

``` ruby
scheduler = Continuity::Scheduler.new_using_redis(redis_handle, :discard_past => false)
```


## Running tests

To run the tests, you'll need to have Redis and Zookeeper running locally.  Zookeeper doesn't require
any special setup - just make sure it's running on `localhost:2181`.  There is a config file located in
`test/redis.conf` - start redis with `redis-server test/redis.conf` before running tests.


## Contributing to continuity
 
* Check out the latest master to make sure the feature hasn't been implemented or the bug hasn't been fixed yet
* Check out the issue tracker to make sure someone already hasn't requested it and/or contributed it
* Fork the project
* Start a feature/bugfix branch
* Commit and push until you are happy with your contribution
* Make sure to add tests for it. This is important so I don't break it in a future version unintentionally.
* Please try not to mess with the Rakefile, version, or history. If you want to have your own version, or is otherwise necessary, that is fine, but please isolate to its own commit so I can cherry-pick around it.

# Copyright

Copyright (c) 2013 Bob Potter. See LICENSE.txt for further details.

