
module Ruck

  class Shred
    attr_accessor :now
    attr_accessor :finished
    attr_accessor :name

    def initialize(shreduler, now, name, &block)
      @shreduler = shreduler
      @now = now
      @name = name
      @block = block
      @finished = false
    end

    def go(resume)
      @resume = resume
      
      # TODO
      # I don't think this is the right place to catch errors.
      # I've read the strangest memory errors after an exception
      # is caught here; I have a feeling exceptions ought to be
      # caught within the continuation itself.
      begin
        @block.call self
      rescue => e
        LOG.error "#{self} exited uncleanly:\n#{e}\n#{e.backtrace}"
      end
      
      @finished = true
      @shreduler.remove_shred self
    end

    def yield(samples)
      LOG.debug "shred #{self} yielding #{samples}"
      @now += samples
      callcc do |cont|
        @block = cont # save where we are
        @resume.call # jump back to shreduler
      end
      samples
    end

    def finish
      @finished = true
      @shreduler.remove_shred self
      
      if @shreduler.current_shred == self
        @resume.call # last save point
      end
    end

    # shreds sort in order of position in time
    def <=>(shred)
      @now <=> shred.now
    end

    def to_s
      "<Shred: #{@name}>"
    end
  end

  class Shreduler
    attr_reader :running
    attr_reader :current_shred
    attr_reader :shreds
    attr_reader :now

    def initialize
      @shreds = []
      @now = 0
      @running = false
    end

    def spork(name = "", &shred_block)
      shred = Shred.new(self, @now, name, &shred_block)
      LOG.debug "Adding shred \"#{shred.name}\" at #{@now}"
      @shreds << shred
      shred
    end

    def remove_shred(shred)
      LOG.debug "Removing shred \"#{shred.name}\" at #{@now}"
      @shreds.delete shred
    end
    
    def next_shred
      @shreds.min # furthest behind (Shred#<=> uses Shred's current time)
    end

    # called when shreds allow time to pass
    # a convenient method to override
    def sim_to(new_now)
      @now = new_now
    end
    
    def invoke_shred(shred)
      # execute shred, saving this as the resume point
      LOG.debug "resuming shred #{@current_shred} at #{now}"
      @current_shred = shred
      callcc { |cont| @current_shred.go(cont) }
      LOG.debug "back to run loop"
    end
    
    # invokes the next shred, simulates to the new VM time, then returns
    def run_one
      shred = next_shred
      
      sim_to(shred.now)
      
      invoke_shred(shred)

      if @current_shred.finished
        LOG.debug "#{shred} finished"
        remove_shred(shred)
      end
    end

    # executes until all shreds exit
    def run
      LOG.debug "shreduler starting"
      @running = true

      while @shreds.length > 0
        run_one
      end

      @running = false
    end
  end

end
