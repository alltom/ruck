
module Ruck
  
  # A resumable Proc implemented using continuation. If the given
  # block calls #pause during its execution, its execution is paused
  # and the caller resumed. The second time the Shred is called, it
  # resumes where it left off.
  # 
  # If #pause is called anywhere but inside the given block, I can
  # almost guarantee that strange things will happen.
  
  class CallccShred
    def initialize(&block)
      @proc = block || Proc.new{}
    end
    
    # pause execution by saving this execution point and returning
    # to the point where go was called
    def pause
      callcc do |cont|
        @proc = cont
        @caller.call
      end
    end
    
    # begin or resume execution
    def call
      return unless @proc
      
      callcc do |cont|
        @caller = cont
        @proc.call self
        
        # if we made it here, we're done
        @proc = nil
        @caller.call
      end
    end
    
    # alias for call. It takes arguments, but ignores them.
    def [](*args)
      call
    end
    
    # returns true if calling this Shred again will have no effect
    def finished?
      @proc.nil?
    end
    
    # makes it so calling this Shred in the future will have no effect
    def kill
      @proc = nil
    end
  end
  
  # See the documentation for CallccShred
  class FiberShred
    def initialize(&block)
      @fiber = Fiber.new(&block)
    end
    
    def pause
      Fiber.yield
    end
    
    def call
      return unless @fiber
      @fiber.resume(self)
    rescue FiberError
      @fiber = nil
    end
    
    def [](*args)
      call
    end
    
    def finished?
      @fiber.nil?
    end
    
    def kill
      @fiber = nil
    end
  end
  
  # Fiber was introduced in Ruby 1.9 and supports a cleaner implementation
  # of Shred than the callcc-based version, but I would like to support
  # Ruby 1.8 as well.
  if defined? Fiber
    class Shred < FiberShred
    end
  else
    class Shred < CallccShred
    end
  end
end
