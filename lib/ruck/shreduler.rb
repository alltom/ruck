
module Ruck
  class Shreduler
    attr_reader :clock
    
    def initialize
      @clock = Clock.new
    end
    
    def now
      @clock.now
    end
    
    def shredule(shred, time = nil)
      @clock.shredule(shred, time)
    end
    
    def unshredule(shred)
      @clock.unshredule(shred)
    end
    
    def run_one
      shred, relative_time = @clock.unshredule_next_shred
      return nil unless shred
      
      fast_forward(relative_time) if relative_time > 0
      
      begin
        @current_shred = shred
        shred.go
      ensure
        @current_shred = nil
      end
      
      shred
    end
    
    def run
      loop { return unless run_one }
    end
    
    protected
      
      def fast_forward(dt)
        @clock.fast_forward(dt)
      end
  end
end
