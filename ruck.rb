require "logger"

LOG = Logger.new(STDOUT)

module Ruck

  SAMPLE_RATE = 22050
  BITS_PER_SAMPLE = 16
  
  def blackhole
    @@blackhole ||= Bus.new
  end
  
  def run
    @shreduler ||= Shreduler.new
    log.error("Ruck already running") and return if @shreduler.running
    @shreduler.run
  end
  
  def spork(name = "unnamed", &shred)
    @shreduler ||= Shreduler.new
    @shreduler.spork(name, &shred)
  end
  
  def play(samples)
    @shreduler.current_shred.yield(samples)
  end
  
  def finish
    shred = @shreduler.current_shred
    @shreduler.remove_shred shred
    shred.finish
  end

end

require File.join(File.dirname(__FILE__), "shreduling")
require File.join(File.dirname(__FILE__), "time")
require File.join(File.dirname(__FILE__), "misc", "metaid")
require File.join(File.dirname(__FILE__), "misc", "linkage")
require File.join(File.dirname(__FILE__), "ugen", "general")
require File.join(File.dirname(__FILE__), "ugen", "wav")
require File.join(File.dirname(__FILE__), "ugen", "oscillators")


# run the ruck script

if __FILE__ == $0
  
  include Ruck
  
  LOG.level = Logger::WARN

  unless File.readable?(ARGV[0])
    LOG.fatal "Cannot read file #{ARGV[0]}"
    exit
  end

  spork("main") { require ARGV[0] }
  run
  
end
