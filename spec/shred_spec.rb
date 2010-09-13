
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
    
    it "should resume execution" do
      $ran = 0
      
      @shred = Shred.new do
        $ran = 1
        Shred.current.pause
        $ran = 2
      end
      
      @shred.call
      $ran.should == 1
      @shred.call
      $ran.should == 2
    end
    
    it "should not mind if you run it too many times" do
      @shred = Shred.new { }
      @shred.call
      @shred.call
    end
    
    it "should not let you pause the wrong shred" do
      @shred1 = Shred.new do
        @shred2.call
      end
      @shred2 = Shred.new do
        @shred1.pause
        $shred2_ran = true
      end
      
      $shred2_ran = false
      @shred1.call
      $shred2_ran.should be_true
    end
    
    it "should let you use [] instead of #call" do
      $ran = false
      @shred = Shred.new { $ran = true }
      @shred[]
      $ran.should == true
    end
  end
  
  context "when killing" do
    it "should not resume the next time you call it" do
      $ran = 0
      
      @shred = Shred.new do
        $ran = 1
        Shred.current.pause
        $ran = 2
      end
      
      @shred.call
      $ran.should == 1
      @shred.kill
      @shred.call
      $ran.should == 1
    end
  end
  
  context "when checking finished? and running?" do
    it "finished? should be false just after creation" do
      @shred = Shred.new { }
      @shred.finished?.should be_false
      @shred.running?.should be_true
    end
    
    it "finished? should be true just after executing the shred for the last time" do
      pending "not yet supported in Ruby 1.9 because Fiber#alive? is missing"
      @shred = Shred.new { }
      @shred.call
      @shred.finished?.should be_true
      @shred.running?.should be_false
    end
    
    it "finished? should be true just after killing the shred" do
      @shred = Shred.new { }
      @shred.kill
      @shred.finished?.should be_true
      @shred.running?.should be_false
    end
  end
  
  context "when calling a shred from a shred" do
    it "should update Shred.current appropriately when the inner shred returns" do
      @shred1 = Shred.new do
        Shred.current.should == @shred1
        @shred2.call
        Shred.current.should == @shred1
      end
      @shred2 = Shred.new do
        Shred.current.should == @shred2
        $shred2_ran = true
      end
      
      $shred2_ran = false
      @shred1.call
      $shred2_ran.should be_true
    end
  end
end
