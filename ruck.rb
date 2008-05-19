
module Ruck

  CHANNELS = 1
  SAMPLE_RATE = 44100
  BITS_PER_SAMPLE = 16

  module Target
    def <<(ugen)
      @ins << ugen
    end
  
    def >>(ugen)
      @ins.delete(ugen)
    end
  end

  module Source
    def next; 0; end
    def last; 0; end
  end

  module Oscillator
    def self.included(base)
      base.instance_eval do
        attr_accessor :freq
        attr_accessor :phase
      end
    end
  end

  class Gain
    include Source
    include Target
    
    def initialize(gain = 1.0)
      @gain = gain
      @ins = []
    end
  
    def next
      @ins.inject(0) { |samp, ugen| samp += ugen.next } * @gain
    end
    
    def to_s
      "<Gain: gain:#{@gain}>"
    end
  end

  class SinOsc
    include Source
    include Oscillator
  
    attr_accessor :gain
  
    def initialize(freq = 440.0, gain = 1.0)
      @freq = freq
      @gain = gain
      @phase = 0.0
    end
  
    def next
      samp = @gain * Math.sin(@phase * 2 * Math::PI)
      @phase += @freq.to_f / SAMPLE_RATE.to_f
      samp
    end
    
    def to_s
      "<SinOsc: freq:#{@freq} gain:#{@gain}>"
    end
  end
  
  class Shred
    attr_accessor :now
    
    def initialize(shreduler, now, name, &block)
      @shreduler = shreduler
      @now = now
      @name = name
      @block = block
      @paused = true
    end
    
    # returns true when completed
    def go(resume)
      @resume = resume
      @block.call(self)
      @paused = false # finished
    end
    
    def finished
      @paused == false
    end
    
    def yield(samples)
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

require "wav"
