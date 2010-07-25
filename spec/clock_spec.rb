
require "ruck"

include Ruck

class MockShred
  def self.next_name
    @@next_name ||= "a"
    name = @@next_name
    @@next_name = @@next_name.succ
    name
  end
  
  def initialize
    @name = MockShred.next_name
  end
  
  def inspect
    "MockShred<#{@name}>"
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
  
  context "when shreduling" do
    it "should default to using the current time" do
      @clock.fast_forward(3)
      @shred = MockShred.new
      @clock.shredule(@shred)
      @clock.next_shred.should == [@shred, 0]
    end
    
    it "should use the given time if provided" do
      @clock.fast_forward(3)
      @shred = MockShred.new
      @clock.shredule(@shred, 5)
      @clock.next_shred.should == [@shred, 2]
    end
    
    context "with no shreds" do
      it "next_shred should be nil" do
        @clock.next_shred.should == nil
      end
    end
    
    context "with multiple shreds" do
      before(:each) do
        @next_shred = MockShred.new
        @shred_after = MockShred.new
        @clock.shredule(@shred_after, 2)
        @clock.shredule(@next_shred, 1)
      end
      
      it "knows the next shreduled shred" do
        @clock.next_shred.should == [@next_shred, 1]
      end
      
      it "can dequeue the next shreduled shred" do
        @clock.unshredule_next_shred.should == [@next_shred, 1]
        @clock.next_shred.should == [@shred_after, 2]
      end
      
      it "can enqueue and dequeue a new shred" do
        @last_shred = MockShred.new
        @clock.shredule(@last_shred, 3)
        @clock.unshredule_next_shred.should == [@next_shred, 1]
        @clock.unshredule_next_shred.should == [@shred_after, 2]
        @clock.next_shred.should == [@last_shred, 3]
      end
      
      it "can interleavedly enqueue and dequeue a new shred" do
        @last_shred = MockShred.new
        @clock.unshredule_next_shred.should == [@next_shred, 1]
        @clock.shredule(@last_shred, 1)
        @clock.unshredule_next_shred.should == [@last_shred, 1]
        @clock.next_shred.should == [@shred_after, 2]
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
    
    context "when finding the next shred" do
      it "should return the correct time offset" do
        @shred = MockShred.new
        @clocks[2].shredule(@shred, 4)
        @clock.next_shred.should == [@shred, 2]
      end
      
      it "should return the correct time offset in a sub-clock 2 levels deep" do
        @shred = MockShred.new
        @clocks[3].shredule(@shred, 8)
        @clock.next_shred.should == [@shred, 2]
      end
      
      it "should return the correct time offset after a fast-forward" do
        @shred = MockShred.new
        @clocks[2].shredule(@shred, 4)
        @clock.fast_forward(1)
        @clock.next_shred.should == [@shred, 1]
      end
      
      it "should return the correct time offset in a sub-clock 2 levels deep after a fast-forward" do
        @shred = MockShred.new
        @clocks[3].shredule(@shred, 8)
        @clock.fast_forward(1)
        @clock.next_shred.should == [@shred, 1]
      end
    end
    
    context "when dequeuing the next shred" do
      it "should work when the shred is on the parent clock" do
        @shred = MockShred.new
        @clocks[0].shredule(@shred, 4)
        @clock.unshredule_next_shred.should == [@shred, 4]
      end
      
      it "should work when the shred is one clock deep" do
        @shred = MockShred.new
        @clocks[1].shredule(@shred, 4)
        @clock.unshredule_next_shred.should == [@shred, 4]
      end
      
      it "should work when the shred is one clock deep and account for rate" do
        @shred = MockShred.new
        @clocks[2].shredule(@shred, 4)
        @clock.unshredule_next_shred.should == [@shred, 2]
      end
      
      it "should work when the shred is two clocks deep and account for rate" do
        @shred = MockShred.new
        @clocks[3].shredule(@shred, 4)
        @clock.unshredule_next_shred.should == [@shred, 1]
      end
    end
  end
  
  context "when dequeuing shreds" do
    it "should work" do
      @shred = MockShred.new
      @clock.shredule(@shred, 2)
      @clock.unshredule(@shred).should == 2
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
        @shred = MockShred.new
        @clocks[0].shredule(@shred, 2)
        @clocks[0].unshredule(@shred).should == 2
      end
      
      it "should work one clock deep" do
        @shred = MockShred.new
        @clocks[1].shredule(@shred, 2)
        @clocks[0].unshredule(@shred).should == 2
      end
      
      it "should work one clock deep and adjust for rate" do
        @shred = MockShred.new
        @clocks[2].shredule(@shred, 2)
        @clocks[0].unshredule(@shred).should == 1
      end
      
      it "should work two clocks deep and adjust for rate" do
        @shred = MockShred.new
        @clocks[3].shredule(@shred, 4)
        @clocks[0].unshredule(@shred).should == 1
      end
    end
  end
end
