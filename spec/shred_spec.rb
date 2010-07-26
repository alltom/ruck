
require "ruck"

include Ruck

describe Shred do
  context "when calling call" do
    it "should execute the given block" do
      $ran = false
      @shred = Shred.new { $ran = true }
      @shred.call
      $ran.should == true
    end
    
    it "should pass itself to the block" do
      $passed_shred = nil
      @shred = Shred.new { |s| $passed_shred = s }
      @shred.call
      $passed_shred.should == @shred
    end
    
    it "should resume execution" do
      $ran = 0
      
      @shred = Shred.new do |shred|
        $ran = 1
        shred.pause
        $ran = 2
      end
      
      @shred.call
      $ran.should == 1
      @shred.call
      $ran.should == 2
    end
    
    it "should not mind if you run it to many times" do
      @shred = Shred.new { }
      @shred.call
      @shred.call
    end
  end
end
