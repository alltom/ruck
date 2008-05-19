
module Ruck

  CHANNELS = 1
  SAMPLE_RATE = 44100
  BITS_PER_SAMPLE = 16
  
  class Shred
    attr_accessor :now
    attr_accessor :finished
    
    def initialize(shreduler, now, name, &block)
      @shreduler = shreduler
      @now = now
      @name = name
      @block = block
      @finished = false
    end
    
    def go(resume)
      @resume = resume
      @block.call(self)
      @finished = true
    end
    
    def yield(samples)
      samples = samples.to_i
      samples = 0 if samples < 0
      puts "#{self} yielding #{samples} samples"
      @now += samples
      callcc do |cont|
        @block = cont
        @resume.call # jump back to shreduler
      end
    end
    
    def <=>(shred)
      @now <=> shred.now
    end
    
    def to_s
      "<Shred: #{@name}>"
    end
  end
  
  class Shreduler
    def initialize
      @shreds = []
      @now = 0
    end
    
    def spork(name, &shred)
      puts "Adding shred \"#{name}\" at #{@now}"
      @shreds << Shred.new(self, @now, name, &shred)
    end
    
    def sim
      min = @shreds.min.now
      puts "catching up #{min - @now} samples"
      (min - @now).times { Ruck.dac.next }
      @now = min
    end
    
    def run
      puts "shreduler starting"
      
      while @shreds.length > 0
        sim
        shred = @shreds.min
        puts "giving #{shred} a chance"
        callcc { |cont| shred.go(cont) }
        if shred.finished
          puts "#{shred} finished"
          @shreds.delete(shred)
        end
      end
    end
  end
  
  def dac
    @@dac ||= Gain.new
  end
  
  def blackhole
    return @@blackhole if defined? @@blackhole
    
    @@blackhole = Gain.new(0.0)
    dac << @@blackhole
    @@blackhole
  end
  
  def run
    # check for re-entry
    @shreduler ||= Shreduler.new
    @shreduler.run
  end
  
  def spork(name = "unnamed", &shred)
    @shreduler ||= Shreduler.new
    @shreduler.spork(name, &shred)
  end

end

class Fixnum
  def second
    self * Ruck::SAMPLE_RATE
  end
  alias_method :seconds, :second
end

class Float
  def second
    self * Ruck::SAMPLE_RATE
  end
  alias_method :seconds, :second
end

require File.join(File.dirname(__FILE__), "ugen", "general")
require File.join(File.dirname(__FILE__), "ugen", "wav")
require File.join(File.dirname(__FILE__), "ugen", "osc")
