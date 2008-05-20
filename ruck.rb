
module Ruck

  CHANNELS = 1
  SAMPLE_RATE = 44100
  BITS_PER_SAMPLE = 16
  
  class Shred
    attr_reader :now
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
      @block.call
      @finished = true
    end
    
    def yield(samples)
      samples = samples.to_i
      samples = 0 if samples < 0
      @now += samples
      callcc do |cont|
        @block = cont
        @resume.call # jump back to shreduler
      end
      samples
    end
    
    def <=>(shred)
      @now <=> shred.now
    end
    
    def to_s
      "<Shred: #{@name}>"
    end
  end
  
  class Shreduler
    attr_reader :running
    attr_reader :current_shred
    
    def initialize
      @shreds = []
      @now = 0
      @running = false
    end
    
    def spork(name, &shred)
      puts "Adding shred \"#{name}\" at #{@now}"
      @shreds << Shred.new(self, @now, name, &shred)
    end
    
    def sim
      min = @shreds.min.now
      (min - @now).times do
        dac.next
        @now += 1
        puts "#{@now / SAMPLE_RATE} seconds rendered..." if @now % SAMPLE_RATE == 0
      end
      @now = min
    end
    
    def run
      puts "shreduler starting"
      @running = true
      
      while @shreds.length > 0
        sim
        @current_shred = @shreds.min
        callcc { |cont| @current_shred.go(cont) }
        if @current_shred.finished
          puts "#{@current_shred} finished"
          @shreds.delete(@current_shred)
        end
      end
      
      @running = false
    end
  end
  
  def dac
    @@dac ||= Gain.new
  end
  
  def blackhole
    return @@blackhole if defined? @@blackhole
    
    @@blackhole = Gain.new(0.0)
    @@blackhole >> dac
    @@blackhole
  end
  
  def run
    @shreduler ||= Shreduler.new
    $stderr.puts("Ruck already running") and return if @shreduler.running
    @shreduler.run
  end
  
  def spork(name = "unnamed", &shred)
    @shreduler ||= Shreduler.new
    @shreduler.spork(name, &shred)
  end
  
  def play(samples)
    @shreduler.current_shred.yield(samples)
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
