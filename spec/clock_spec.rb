
require "ruck"

include Ruck

class MockOccurrenceObj
  def self.next_name
    @@next_name ||= "a"
    name = @@next_name
    @@next_name = @@next_name.succ
    name
  end
  
  def initialize
    @name = MockOccurrenceObj.next_name
  end
  
  def inspect
    "MockOccurrenceObj<#{@name}>"
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
      @occurrence = MockOccurrenceObj.new
      @clock.schedule(@occurrence)
      @clock.next.should == [@occurrence, 0]
    end
    
    it "should use the given time if provided" do
      @clock.fast_forward(3)
      @occurrence = MockOccurrenceObj.new
      @clock.schedule(@occurrence, 5)
      @clock.next.should == [@occurrence, 2]
    end
    
    context "with no occurrences" do
      it "next should be nil" do
        @clock.next.should == nil
      end
    end
    
    context "with multiple occurrences" do
      before(:each) do
        @next_occurrence = MockOccurrenceObj.new
        @occurrence_after = MockOccurrenceObj.new
        @clock.schedule(@occurrence_after, 2)
        @clock.schedule(@next_occurrence, 1)
      end
      
      it "knows the next scheduled occurrence" do
        @clock.next.should == [@next_occurrence, 1]
      end
      
      it "can dequeue the next scheduled occurrence" do
        @clock.unschedule_next.should == [@next_occurrence, 1]
        @clock.next.should == [@occurrence_after, 2]
      end
      
      it "can enqueue and dequeue a new occurrence" do
        @last_occurrence = MockOccurrenceObj.new
        @clock.schedule(@last_occurrence, 3)
        @clock.unschedule_next.should == [@next_occurrence, 1]
        @clock.unschedule_next.should == [@occurrence_after, 2]
        @clock.next.should == [@last_occurrence, 3]
      end
      
      it "can interleavedly enqueue and dequeue a new occurrence" do
        @last_occurrence = MockOccurrenceObj.new
        @clock.unschedule_next.should == [@next_occurrence, 1]
        @clock.schedule(@last_occurrence, 1)
        @clock.unschedule_next.should == [@last_occurrence, 1]
        @clock.next.should == [@occurrence_after, 2]
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
    
    context "when finding the next occurrence" do
      it "should return the correct time offset" do
        @occurrence = MockOccurrenceObj.new
        @clocks[2].schedule(@occurrence, 4)
        @clock.next.should == [@occurrence, 2]
      end
      
      it "should return the correct time offset in a sub-clock 2 levels deep" do
        @occurrence = MockOccurrenceObj.new
        @clocks[3].schedule(@occurrence, 8)
        @clock.next.should == [@occurrence, 2]
      end
      
      it "should return the correct time offset after a fast-forward" do
        @occurrence = MockOccurrenceObj.new
        @clocks[2].schedule(@occurrence, 4)
        @clock.fast_forward(1)
        @clock.next.should == [@occurrence, 1]
      end
      
      it "should return the correct time offset in a sub-clock 2 levels deep after a fast-forward" do
        @occurrence = MockOccurrenceObj.new
        @clocks[3].schedule(@occurrence, 8)
        @clock.fast_forward(1)
        @clock.next.should == [@occurrence, 1]
      end
    end
    
    context "when dequeuing the next occurrence" do
      it "should work when the occurrence is on the parent clock" do
        @occurrence = MockOccurrenceObj.new
        @clocks[0].schedule(@occurrence, 4)
        @clock.unschedule_next.should == [@occurrence, 4]
      end
      
      it "should work when the occurrence is one clock deep" do
        @occurrence = MockOccurrenceObj.new
        @clocks[1].schedule(@occurrence, 4)
        @clock.unschedule_next.should == [@occurrence, 4]
      end
      
      it "should work when the occurrence is one clock deep and account for rate" do
        @occurrence = MockOccurrenceObj.new
        @clocks[2].schedule(@occurrence, 4)
        @clock.unschedule_next.should == [@occurrence, 2]
      end
      
      it "should work when the occurrence is two clocks deep and account for rate" do
        @occurrence = MockOccurrenceObj.new
        @clocks[3].schedule(@occurrence, 4)
        @clock.unschedule_next.should == [@occurrence, 1]
      end
    end
  end
  
  context "when dequeuing occurrences" do
    it "should work" do
      @occurrence = MockOccurrenceObj.new
      @clock.schedule(@occurrence, 2)
      @clock.unschedule(@occurrence).should == 2
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
        @occurrence = MockOccurrenceObj.new
        @clocks[0].schedule(@occurrence, 2)
        @clocks[0].unschedule(@occurrence).should == 2
      end
      
      it "should work one clock deep" do
        @occurrence = MockOccurrenceObj.new
        @clocks[1].schedule(@occurrence, 2)
        @clocks[0].unschedule(@occurrence).should == 2
      end
      
      it "should work one clock deep and adjust for rate" do
        @occurrence = MockOccurrenceObj.new
        @clocks[2].schedule(@occurrence, 2)
        @clocks[0].unschedule(@occurrence).should == 1
      end
      
      it "should work two clocks deep and adjust for rate" do
        @occurrence = MockOccurrenceObj.new
        @clocks[3].schedule(@occurrence, 4)
        @clocks[0].unschedule(@occurrence).should == 1
      end
    end
  end
end
