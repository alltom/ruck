
module Ruck

  class Shred
    attr_reader :now
    attr_accessor :finished

    def initialize(shreduler, now, name, &block)
      @shreduler = shreduler
      @now = now
      @name = name
      @block = block
      @finished = false
    end

    def go(resume)
      @resume = resume
      begin
        @block.call
      rescue => e
        LOG.error "#{self} exited uncleanly:\n#{e}\n#{e.backtrace}"
      end
      @finished = true
    end

    def yield(samples)
      samples = samples.to_i
      @now += samples
      callcc do |cont|
        @block = cont # save where we are
        @resume.call # jump back to shreduler
      end
      samples
    end

    def finish
      @resume.call # last save point
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

    def spork(name, &shred)
      LOG.debug "Adding shred \"#{name}\" at #{@now}"
      @shreds << Shred.new(self, @now, name, &shred)
    end

    def remove_shred(shred)
      LOG.debug "Removing shred \"#{name}\" at #{@now}"
      @shreds.delete shred
    end

    # called when shreds allow time to pass
    def sim_to(new_now)
      @now = new_now
    end

    # ruck main loop
    # executes all shreds and synthesizes audio
    #   until all shreds exit
    def run
      LOG.debug "shreduler starting"
      @running = true

      while @shreds.length > 0
        @current_shred = @shreds.min # furthest behind (Shred#<=> uses Shred's current time)
        
        sim_to(@current_shred.now)
        
        # execute shred, saving this as the resume point
        callcc { |cont| @current_shred.go(cont) }

        if @current_shred.finished
          LOG.debug "#{@current_shred} finished"
          @shreds.delete(@current_shred)
        end
      end

      @running = false
    end
  end
  
  class UGenShreduler < Shreduler
    def sim_to(new_now)
      # simulate samples up to furthest behind shred
      # BUG: if all time steps are fractional samples, will this loop ever run?
      (new_now - @now).times do
        BLACKHOLE.next @now
        @now += 1
      end
    end
  end
  
  # TODO: gets out of sync with wall clock too easily
  class RealTimeShreduler < Shreduler
    def sim_to(new_now)
      samples_to_simulate = new_now - @now
      sleep(samples_to_simulate.to_f / SAMPLE_RATE)
      @now += samples_to_simulate
    end
  end

end
