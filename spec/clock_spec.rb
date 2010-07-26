
require "ruck"

include Ruck

class MockEvent
  def self.next_name
    @@next_name ||= "a"
    name = @@next_name
    @@next_name = @@next_name.succ
    name
  end
  
  def initialize
    @name = MockEvent.next_name
  end
  
  def inspect
    "MockEvent<#{@name}>"
  end
end

describe Clock do
  before(:each) do
    @clock = Clock.new
    @clocks = [@clock]
  end
  
  context "when creating" do
    it "starts with now = 0" do
      Clock.new.now.should == 0
    end
  end
  
  context "when fast-forwarding" do
    it "works" do
      @clock.fast_forward(1)
      @clock.now.should == 1
      @clock.fast_forward(1)
      @clock.now.should == 2
    end
  end
  
  context "when scheduling" do
    it "should default to using the current time" do
      @clock.fast_forward(3)
      @event = MockEvent.new
      @clock.schedule(@event)
      @clock.next_event.should == [@event, 0]
    end
    
    it "should use the given time if provided" do
      @clock.fast_forward(3)
      @event = MockEvent.new
      @clock.schedule(@event, 5)
      @clock.next_event.should == [@event, 2]
    end
    
    context "with no events" do
      it "next_event should be nil" do
        @clock.next_event.should == nil
      end
    end
    
    context "with multiple events" do
      before(:each) do
        @next_event = MockEvent.new
        @event_after = MockEvent.new
        @clock.schedule(@event_after, 2)
        @clock.schedule(@next_event, 1)
      end
      
      it "knows the next scheduled event" do
        @clock.next_event.should == [@next_event, 1]
      end
      
      it "can dequeue the next scheduled event" do
        @clock.unschedule_next_event.should == [@next_event, 1]
        @clock.next_event.should == [@event_after, 2]
      end
      
      it "can enqueue and dequeue a new event" do
        @last_event = MockEvent.new
        @clock.schedule(@last_event, 3)
        @clock.unschedule_next_event.should == [@next_event, 1]
        @clock.unschedule_next_event.should == [@event_after, 2]
        @clock.next_event.should == [@last_event, 3]
      end
      
      it "can interleavedly enqueue and dequeue a new event" do
        @last_event = MockEvent.new
        @clock.unschedule_next_event.should == [@next_event, 1]
        @clock.schedule(@last_event, 1)
        @clock.unschedule_next_event.should == [@last_event, 1]
        @clock.next_event.should == [@event_after, 2]
      end
    end
  end
  
  context "with sub-clocks" do
    before do
      # clock/clocks[0]
      # - clocks[1] x1
      # - clocks[2] x2
      #   - clocks[3] x2
      @clocks << @clock.add_child_clock(Clock.new(1))
      @clocks << @clock.add_child_clock(Clock.new(2))
      @clocks << @clocks[2].add_child_clock(Clock.new(2))
    end
    
    context "when fast-forwarding" do
      it "fast-forwards children clocks" do
        @clock.fast_forward(1)
        @clocks[1].now.should == 1
        @clocks[2].now.should == 2
        @clocks[3].now.should == 4
      end
    end
    
    context "when finding the next event" do
      it "should return the correct time offset" do
        @event = MockEvent.new
        @clocks[2].schedule(@event, 4)
        @clock.next_event.should == [@event, 2]
      end
      
      it "should return the correct time offset in a sub-clock 2 levels deep" do
        @event = MockEvent.new
        @clocks[3].schedule(@event, 8)
        @clock.next_event.should == [@event, 2]
      end
      
      it "should return the correct time offset after a fast-forward" do
        @event = MockEvent.new
        @clocks[2].schedule(@event, 4)
        @clock.fast_forward(1)
        @clock.next_event.should == [@event, 1]
      end
      
      it "should return the correct time offset in a sub-clock 2 levels deep after a fast-forward" do
        @event = MockEvent.new
        @clocks[3].schedule(@event, 8)
        @clock.fast_forward(1)
        @clock.next_event.should == [@event, 1]
      end
    end
    
    context "when dequeuing the next event" do
      it "should work when the event is on the parent clock" do
        @event = MockEvent.new
        @clocks[0].schedule(@event, 4)
        @clock.unschedule_next_event.should == [@event, 4]
      end
      
      it "should work when the event is one clock deep" do
        @event = MockEvent.new
        @clocks[1].schedule(@event, 4)
        @clock.unschedule_next_event.should == [@event, 4]
      end
      
      it "should work when the event is one clock deep and account for rate" do
        @event = MockEvent.new
        @clocks[2].schedule(@event, 4)
        @clock.unschedule_next_event.should == [@event, 2]
      end
      
      it "should work when the event is two clocks deep and account for rate" do
        @event = MockEvent.new
        @clocks[3].schedule(@event, 4)
        @clock.unschedule_next_event.should == [@event, 1]
      end
    end
  end
  
  context "when dequeuing events" do
    it "should work" do
      @event = MockEvent.new
      @clock.schedule(@event, 2)
      @clock.unschedule(@event).should == 2
    end
    
    context "with sub-clocks" do
      before(:each) do
        # clock/clocks[0]
        # - clocks[1] x1
        # - clocks[2] x2
        #   - clocks[3] x2
        @clocks << @clock.add_child_clock(Clock.new(1))
        @clocks << @clock.add_child_clock(Clock.new(2))
        @clocks << @clocks[2].add_child_clock(Clock.new(2))
      end
      
      it "should work with the parent clock" do
        @event = MockEvent.new
        @clocks[0].schedule(@event, 2)
        @clocks[0].unschedule(@event).should == 2
      end
      
      it "should work one clock deep" do
        @event = MockEvent.new
        @clocks[1].schedule(@event, 2)
        @clocks[0].unschedule(@event).should == 2
      end
      
      it "should work one clock deep and adjust for rate" do
        @event = MockEvent.new
        @clocks[2].schedule(@event, 2)
        @clocks[0].unschedule(@event).should == 1
      end
      
      it "should work two clocks deep and adjust for rate" do
        @event = MockEvent.new
        @clocks[3].schedule(@event, 4)
        @clocks[0].unschedule(@event).should == 1
      end
    end
  end
end
