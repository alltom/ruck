
require "rubygems"
require "priority_queue"

module Ruck
  
  # Clock keeps track of occurrences on a virtual timeline. Clocks
  # can be configured to run fast or slow relative to another clock
  # by changing their relative_rate and providing them a parent via
  # add_child_clock.
  # 
  # Clocks and their sub-clocks always tell the same time. When
  # fast_forward is called, they advance in lock-step. You should only
  # call fast_forward on the root of any tree of Clocks.
  # 
  # = A warning about fast_forward and time travel
  # 
  # When using a Clock with no children, there's little reason to ever
  # call fast_forward because in that case Clock is little more than
  # a priority queue. When using a Clock with children, before ever
  # changing a Clock's relative_rate, you should fast_forward to the
  # VIRTUAL instant that change is meant to take place. This ensures
  # that the change happens at that time and future occurrences are
  # scheduled correctly.
  # 
  # (For an example of why this is important, consider two connected
  # clocks, where the child's relative_rate is 1.0. If 5 time units in,
  # the relative_rate is changed to 5,000 and fast_forward(5) isn't
  # called, the first 5 time units of the child's clock are also
  # affected by the change, and some occurrences could afterward take
  # place at t < 5.)
  
  class Clock
    attr_reader :now # current time in this clock's units
    attr_accessor :relative_rate # rate relative to parent clock
    attr_accessor :parent
    
    def initialize(relative_rate = 1.0)
      @relative_rate = relative_rate
      @now = 0
      @children = []
      @occurrences = PriorityQueue.new
    end
    
    def relative_rate=(new_rate)
      @relative_rate = new_rate
      parent.schedule([:clock, self], unscale_time(@occurrences.min_priority))
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
      @children << clock unless @children.include? clock
      clock.parent = self
      clock
    end
    
    # schedules an occurrence at the given time with the given object,
    # defaulting to the current time
    def schedule(obj, time = nil)
      time ||= now
      @occurrences[obj] = time
      parent.schedule([:clock, self], unscale_time(time)) if parent && @occurrences.min_key == obj
    end
    
    # dequeues the earliest occurrence from this clock or any child clocks.
    # returns nil if it wasn't there, or its relative_time otherwise
    def unschedule(obj)
      if @occurrences.has_key? obj
        last_priority = @occurrences.min_priority
        obj, time = @occurrences.delete obj
        if parent && @occurrences.min_priority != last_priority
          if @occurrences.min_priority
            parent.schedule([:clock, self], unscale_time(@occurrences.min_priority))
          else
            parent.unschedule([:clock, self])
          end
        end
        unscale_time(time)
      else
        relative_time = @children.first_non_nil { |clock| clock.unschedule(obj) }
        unscale_relative_time(relative_time) if relative_time
      end
    end
    
    # dequeues every occurrence from this clock and its children
    def clear
      @occurrences = PriorityQueue.new
      @children.each { |child| child.clear }
    end
    
    # returns [obj, relative_time], where relative_time is the offset from
    # now in parent's time units
    def next
      clock, (obj, relative_time) = next_with_clock
      [obj, relative_time] if obj
    end
    
    # unschedules and returns the next object as [obj, relative_time],
    # where relative_time is the offset from now in parent's time units
    def unschedule_next
      clock, (obj, relative_time) = next_with_clock
      if obj
        clock.unschedule(obj)
        [obj, relative_time]
      end
    end
    
    protected
      
      # returns [clock, [obj, relative_time]]
      def next_with_clock
        return nil if @occurrences.length == 0
        
        obj, time = @occurrences.min
        if Array === obj && obj[0] == :clock
          sub_obj, relative_time = obj[1].next
          [obj[1], [sub_obj, unscale_relative_time(relative_time)]]
        else
          [self, [obj, unscale_time(time)]]
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
        relative_time / @relative_rate.to_f
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
