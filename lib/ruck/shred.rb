
module Ruck
  class Shred
    def initialize(&block)
      @proc = block || Proc.new{}
      @finished = false
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
    def go
      return unless @proc
      
      callcc do |cont|
        @caller = cont
        @proc.call self
        
        # if we made it here, we're done
        @proc = nil
        @caller.call
      end
    end
    
    def finished
      @proc.nil?
    end
  end
end
