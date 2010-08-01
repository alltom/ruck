
module Ruck
  
  # A resumable Proc implemented using continuation. If the given
  # block calls #pause during its execution, its execution is paused
  # and the caller resumed. The second time the Shred is called, it
  # resumes where it left off.
  # 
  # If #pause is called anywhere but inside the given block, I can
  # almost guarantee that strange things will happen.
  
  class Shred
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
    
    def [](*args)
      call
    end
    
    def finished?
      @proc.nil?
    end
    
    def kill
      @proc = nil
    end
  end
end
