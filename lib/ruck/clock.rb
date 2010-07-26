
require "rubygems"
require "priority_queue"

module Ruck
  # Clock keeps track of events on a virtual timeline. Clocks can be
  # configured to run fast or slow relative to another clock by
  # changing their relative_rate and providing them a parent via
  # add_child_clock.
  # 
  # Clocks and their sub-clocks are always at the same time; they
  # fast-forward in lock-step. You should not call fast_forward on
  # a clock with a parent.
  class Clock
    attr_reader :now # current time in this clock's units
    attr_accessor :relative_rate # rate relative to parent clock
    
    def initialize(relative_rate = 1.0)
      @relative_rate = relative_rate
      @now = 0
      @children = []
      @events = PriorityQueue.new
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
    
    # schedules an event at the given time (defaulting to the current time)
    def schedule(event, time = nil)
      @events[event] = time || now
    end
    
    # dequeues an event from this clock or any child clocks. returns nil if
    # the event wasn't there, or its relative_time otherwise
    def unschedule(event)
      if @events[event]
        event, time = @events.delete event
        unscale_time(time)
      else
        relative_time = @children.first_non_nil { |clock| clock.unschedule(event) }
        unscale_relative_time(relative_time) if relative_time
      end
    end
    
    # returns [event, relative_time], where relative_time is the offset from
    # now in parent's time units
    def next_event
      clock, (event, relative_time) = next_event_with_clock
      [event, relative_time] if event
    end
    
    # unschedules and returns the next event, returning [event, relative_time],
    # where relative_time is the offset from now in parent's time units
    def unschedule_next_event
      clock, (event, relative_time) = next_event_with_clock
      if event
        clock.unschedule(event)
        [event, relative_time]
      end
    end
    
    protected
      
      # returns [clock, [event, relative_time]]
      def next_event_with_clock
        possible = [] # set of clocks/events to find the min of
        
        if @events.length > 0
          event, time = @events.min
          possible << [self, [event, unscale_time(time)]]
        end
        
        # earliest event of each child, converting to absolute time
        possible += @children.map { |c| [c, c.next_event] }.map do |clock, (event, relative_time)|
          [clock, [event, unscale_relative_time(relative_time)]] if event
        end.compact
        
        possible.min do |(clock1, (event1, time1)), (clock2, (event2, time2))|
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
