
module Ruck
  class EventClock
    attr_reader :now
    
    def initialize
      @now = 0
      @waiting = Hash.new { |hash, event| hash[event] = [] }
      @raised = []
    end
    
    # fast-forward this clock by the given time delta
    def fast_forward(dt)
      @now += dt
    end
    
    def schedule(obj, event = nil)
      @waiting[event] << obj
    end
    
    def unschedule(obj)
      @waiting.each { |event, objs| objs.delete(obj) }
      @raised.delete(obj)
    end
    
    def next
      [@raised.first, 0] if @raised.length > 0
    end
    
    def unschedule_next
      [@raised.shift, 0] if @raised.length > 0
    end
    
    def raise_all(event)
      @raised += @waiting[event]
      @waiting[event] = []
    end
  end
end
