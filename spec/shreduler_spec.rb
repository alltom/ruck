
require "ruck"

include Ruck

class MockShred
  attr_reader :runs
  
  def self.next_name
    @@next_name ||= "a"
    name = @@next_name
    @@next_name = @@next_name.succ
    name
  end
  
  def initialize(runs_until_finished = 1, shreduler = nil)
    @name = MockShred.next_name
    @finished = false
    @runs_until_finished = runs_until_finished
    @shreduler = shreduler
  end
  
  def inspect
    "MockShred<#{@name}>"
  end
  
  def call
    $runs << self
    @runs_until_finished -= 1
    @finished = (@runs_until_finished == 0)
    @shreduler.shredule(self) unless @finished || @shreduler == nil
  end
  
  def finished?
    @finished
  end
end

describe Shreduler do
  before(:each) do
    @shreduler = Shreduler.new
    $runs = []
  end
  
  context "when calling run" do
    # this is internal behavior, but should be tested as run_one is an important override point
    it "should run the shred with run_one" do
      @shreduler.should_receive(:run_one)
      @shreduler.run
    end
    
    context "with one shred" do
      it "should run it" do
        @shred = MockShred.new
        @shreduler.shredule(@shred)
        @shreduler.run
        $runs.should == [@shred]
      end
      
      it "should end up at the shred's shreduled time" do
        @shred = MockShred.new
        @shreduler.shredule(@shred, 3)
        @shreduler.run
        @shreduler.now.should == 3
      end
    end
    
    context "with multiple shreds" do
      it "should run them in order if shreduled in order" do
        @shreds = [MockShred.new, MockShred.new]
        @shreduler.shredule(@shreds[0], 0)
        @shreduler.shredule(@shreds[1], 1)
        @shreduler.run
        
        $runs.should == [@shreds[0], @shreds[1]]
      end
      
      it "should run them in order if shreduled out of order" do
        @shreds = [MockShred.new, MockShred.new]
        @shreduler.shredule(@shreds[1], 1)
        @shreduler.shredule(@shreds[0], 0)
        @shreduler.run
        
        $runs.should == [@shreds[0], @shreds[1]]
      end
      
      it "should run them until they are finished" do
        @shred = MockShred.new(5, @shreduler)
        @shreduler.shredule(@shred, 0)
        @shreduler.run
        
        $runs.should == (1..5).map { @shred }
      end
    end
  end
  
  context "when calling run_one" do
    it "should only run one shred" do
      @shreds = [MockShred.new, MockShred.new]
      @shreduler.shredule(@shreds[1], 1)
      @shreduler.shredule(@shreds[0], 0)
      @shreduler.run_one
      
      $runs.should == [@shreds[0]]
    end
    
    # fast_forward is protected, but a crucial override point, so should be tested
    it "should call fast_forward before executing the shred" do
      $runs_when_fast_forward_triggered = nil
      
      @shreds = [MockShred.new]
      @shreduler.shredule(@shreds[0], 1)
      @shreduler.should_receive(:fast_forward).with(1).and_return { $runs_when_fast_forward_triggered = $runs.dup; nil }
      @shreduler.run_one
      
      $runs_when_fast_forward_triggered.should == []
    end
  end
  
  context "when unshreduling" do
    it "should work" do
      @shred = MockShred.new
      @shreduler.shredule(@shred)
      @shreduler.unshredule(@shred)
      @shreduler.run
      $runs.should == []
    end
  end
end
