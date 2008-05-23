
module Ruck

  CHANNELS = 1
  SAMPLE_RATE = 44100
  BITS_PER_SAMPLE = 16
  
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
  
  def ms
    self * Ruck::SAMPLE_RATE / 1000.0
  end
end

class Float
  def second
    self * Ruck::SAMPLE_RATE
  end
  alias_method :seconds, :second
  
  def ms
    self * Ruck::SAMPLE_RATE / 1000.0
  end
end

require File.join(File.dirname(__FILE__), "misc", "metaid")
require File.join(File.dirname(__FILE__), "linkage")
require File.join(File.dirname(__FILE__), "shreduling")
require File.join(File.dirname(__FILE__), "ugen", "general")
require File.join(File.dirname(__FILE__), "ugen", "wav")
require File.join(File.dirname(__FILE__), "ugen", "osc")
