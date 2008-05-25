
module Ruck

  CHANNELS = 1
  SAMPLE_RATE = 22050
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

module RuckTime
  def ms
    self * Ruck::SAMPLE_RATE / 1000.0
  end
  
  def second
    self * Ruck::SAMPLE_RATE
  end
  alias_method :seconds, :second
  
  def minute
    self * Ruck::SAMPLE_RATE * 60.0
  end
  alias_method :minutes, :minute
end

class Fixnum
  include RuckTime
end

class Float
  include RuckTime
end

require File.join(File.dirname(__FILE__), "shreduling")
require File.join(File.dirname(__FILE__), "misc", "metaid")
require File.join(File.dirname(__FILE__), "misc", "linkage")
require File.join(File.dirname(__FILE__), "ugen", "general")
require File.join(File.dirname(__FILE__), "ugen", "wav")
require File.join(File.dirname(__FILE__), "ugen", "oscillators")

unless File.readable?(ARGV[0])
  $stderr.puts "Cannot read file #{ARGV[0]}"
  exit
end

include Ruck
spork("main") { require ARGV[0] }
run