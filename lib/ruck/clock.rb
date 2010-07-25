
require "rubygems"
require "priority_queue"

module Ruck
  # Clocks and their sub-clocks are always at the same time; they
  # fast-forward in lock-step. You should not call fast_forward on
  # a clock with a parent.
  class Clock
    attr_reader :now # current time in this clock's units
    
    def initialize(relative_rate = 1.0)
      @relative_rate = relative_rate
      @now = 0
      @children = []
      @shreds = PriorityQueue.new
    end
    
    # fast-forward this clock and all children clocks by the given time delta
    def fast_forward(dt)
      adjusted_dt = dt * @relative_rate
      @now += adjusted_dt
      @children.each { |sub_clock| sub_clock.fast_forward(adjusted_dt) }
    end
    
    # adds the given clock as a child of this one. a clock should only be
    # the child of one other clock, please.
    def add_child_clock(clock)
      @children << clock
      clock
    end
    
    def shredule(shred, time = nil)
      @shreds[shred] = time || now
    end
    
    # dequeues a shred from this clock or any child clocks. returns nil if
    # the shred wasn't there, or its relative_time otherwise
    def unshredule(shred)
      if @shreds[shred]
        shred, time = @shreds.delete shred
        unscale_time(time)
      else
        relative_time = @children.first_non_nil { |clock| clock.unshredule(shred) }
        unscale_relative_time(relative_time) if relative_time
      end
    end
    
    # returns [shred, relative_time], where relative_time is the offset from
    # now in parent's time units
    def next_shred
      clock, (shred, relative_time) = next_shred_with_clock
      [shred, relative_time] if shred
    end
    
    # deshredules and returns [shred, relative_time], where relative_time is
    # the offset from now in parent's time units
    def unshredule_next_shred
      clock, (shred, relative_time) = next_shred_with_clock
      if shred
        clock.unshredule(shred)
        [shred, relative_time]
      end
    end
    
    protected
      
      def next_shred_with_clock
        possible = [] # set of clocks/shreds to find the min of
        
        if @shreds.length > 0
          shred, time = @shreds.min
          possible << [self, [shred, unscale_time(time)]]
        end
        
        # min shred of each child, converting to absolute time
        possible += @children.map { |c| [c, c.next_shred] }.map do |clock, (shred, relative_time)|
          [clock, [shred, unscale_time(now + relative_time)]] if shred
        end.compact
        
        possible.min do |(clock1, (shred1, time1)), (clock2, (shred2, time2))|
          time1[1] <=> time2[1]
        end
      end
      
      # convert an absolute time in this clock's units to an offset from
      # now in parent clock's units
      def unscale_time(time)
        unscale_relative_time(time - now)
      end
      
      # convert an offset from now in this clock's units to a time
      # delta from now in parent clock's units
      def unscale_relative_time(relative_time)
        relative_time / @relative_rate
      end
  end
end

module Enumerable
  def first_non_nil
    each do |o|
      val = yield o
      return val if val
    end
    nil
  end
end
