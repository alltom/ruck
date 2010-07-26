
module Ruck
  class Shreduler
    attr_reader :clock
    
    def initialize
      @clock = Clock.new
    end
    
    def now
      @clock.now
    end
    
    def shredule(shred, time = nil, clock = nil)
      (clock || @clock).schedule(shred, time)
    end
    
    def unshredule(shred)
      @clock.unschedule(shred)
    end
    
    def run_one
      shred, relative_time = @clock.unschedule_next_event
      return nil unless shred
      
      fast_forward(relative_time) if relative_time > 0
      
      begin
        @current_shred = shred
        shred.call
      ensure
        @current_shred = nil
      end
      
      shred
    end
    
    def run
      loop { return unless run_one }
    end
    
    # makes this the global shreduler
    def make_convenient
      $shreduler = self
      
      Shred.module_eval { include ShredConvenienceMethods }
      Object.module_eval { include KernelConvenienceMethods }
    end
    
    protected
      
      def fast_forward(dt)
        @clock.fast_forward(dt)
      end
  end
  
  module ShredConvenienceMethods
    def yield(dt, clock = nil)
      $shreduler.shredule(self, $shreduler.now + dt, clock)
      pause
    end
  end
  
  module KernelConvenienceMethods
    def spork(&block)
      $shreduler.shredule(Shred.new(&block))
    end
  end
end
