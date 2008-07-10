require "logger"

LOG = Logger.new(STDOUT)

module Ruck

  SAMPLE_RATE = 22050
  BITS_PER_SAMPLE = 16

  def blackhole
    @@blackhole ||= InChannel.new
  end
  
  def now
    @shreduler.now
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
require File.join(File.dirname(__FILE__), "misc", "time")
require File.join(File.dirname(__FILE__), "misc", "metaid")
require File.join(File.dirname(__FILE__), "misc", "linkage")
require File.join(File.dirname(__FILE__), "ugen", "general")
require File.join(File.dirname(__FILE__), "ugen", "wav")
require File.join(File.dirname(__FILE__), "ugen", "oscillators")


# run the ruck scripts

if __FILE__ == $0

  include Ruck

  LOG.level = Logger::WARN

  filenames = ARGV
  filenames.each do |filename|
    unless File.readable?(filename)
      LOG.fatal "Cannot read file #{filename}"
      exit
    end
  end

  filenames.each { |filename| spork("main") { require filename } }
  run

end
