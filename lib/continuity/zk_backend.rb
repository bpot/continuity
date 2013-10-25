require 'zk'
require 'socket'

module Continuity
  class ZkBackend
    attr_reader :zk, :frequency, :zk_key, :election_name, :candidate, :mutex

    # Zookeeper Backend
    #
    # Uses Zookeeper to elect a single, persistent scheduler processes.  This process will remain
    # the scheduler until it is shut down or dies, at which point another scheduler will be
    # elected.  Tracks the latest time successfully scheduled, so failed time periods will be
    # retried by the newly elected eladers
    #
    #
    # zookeepers:       See ZK:Client::Base constructor for syntax details
    # args:
    #   frequency       The number of seconds to wait before checking if scheduled tasks are due
    #   zk_key          The Zookeeper node used to store the successfully scheduled timestamp
    #   election_name   Zk::Election::Candidate election name, change if you need multiple scheduling groups
    #   loop            Exit the main loop after a single execution if false
    #
    def initialize(zookeepers, args={})
      @zk             = ZK.new(zookeepers)
      @namespace      = args[:namespace].gsub('/', '__')
      @frequency      = args[:frequency] || 10
      @zk_key         = args[:zk_key] || ["/_continuity_scheduled_up_to", @namespace].compact.join('__')
      @election_name  = args[:election_name] || ["continuity_scheduler", @namespace].compact.join('__')
      @loop           = args.has_key?(:loop) ? args[:loop] : true
      @mutex          = Mutex.new

      @leader         = false
    end

    def each_epoch(&block)
      # Only one ZkBackend instance will win an election at a time
      # The winning instance remains the leader until it dies
      candidate.on_winning_election do
        # The mutex shouldn't be necessary, but let's be safe
        mutex.synchronize { @leader = true } 
      end

      # It's unlikely that an instance will win an election and subsequently
      # lose one, but just in case...
      candidate.on_losing_election do
        mutex.synchronize { @leader = false }
      end

      # Start the election process.  One of the callbacks above will
      # be triggered
      candidate.vote!

      # The callbacks above are inteded to be non-blocking - ZK acknowledges that a leader
      # has been elected after the callback exits.  So we need to do the actual work of
      # leading here.
      loop do
        maybe_schedule(&block) if leader?
        sleep frequency
        break unless loop?
      end
    ensure
      zk.close
    end
    
    def candidate
      @candidate ||= ZK::Election::Candidate.new(@zk, election_name, :data => id)
    end

    private

    # If scheduled tasks are ready to be executed, do them
    #
    def maybe_schedule(&block)
      now = Time.now.to_i
      begin
        scheduled_up_to = zk.get(zk_key).first.to_i
      rescue ZK::Exceptions::NoNode
        scheduled_up_to = now - 1
        zk.create(zk_key, scheduled_up_to.to_s)
      end

      if now > scheduled_up_to
        block.call( (scheduled_up_to...now) )
        zk.set(zk_key, now.to_s)
      end
    end

    # Unique identifier across machies, processes and threads.
    # Used to identify the election winner
    #
    def id
     [Socket.gethostname, $$, Thread.current.object_id].join('.')
    end

    def loop?
      @loop
    end
  
    def leader?
      !!@leader
    end
  end
end
