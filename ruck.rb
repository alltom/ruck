
#  used throughout ruck libraries
require "logger"
LOG = Logger.new(STDOUT)

# stuff accessible in a shred
module ShredLocal

  def blackhole
    BLACKHOLE
  end
  
  def now
    SHREDULER.now
  end

  def spork(name = "unnamed", &shred)
    SHREDULER.spork(name, &shred)
  end

  def play(samples)
    SHREDULER.current_shred.yield(samples)
  end

  def finish
    shred = SHREDULER.current_shred
    SHREDULER.remove_shred shred
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

  SAMPLE_RATE = 22050
  SHREDULER = Ruck::UGenShreduler.new
  BLACKHOLE = Ruck::InChannel.new

  LOG.level = Logger::WARN

  filenames = ARGV
  filenames.each do |filename|
    unless File.readable?(filename)
      LOG.fatal "Cannot read file #{filename}"
      exit
    end
  end

  filenames.each do |filename|
    SHREDULER.spork(filename) do
      include ShredLocal
      include Ruck::Generators
      require filename
    end
  end
  SHREDULER.run

end
