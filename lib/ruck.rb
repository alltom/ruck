
module Ruck
  require "logger"
  LOG = Logger.new(STDOUT)
  LOG.level = Logger::WARN
end

require File.join(File.dirname(__FILE__), "ruck", "shreduling")
require File.join(File.dirname(__FILE__), "ruck", "misc", "metaid")
require File.join(File.dirname(__FILE__), "ruck", "misc", "linkage")
require File.join(File.dirname(__FILE__), "ruck", "ugen", "general")
require File.join(File.dirname(__FILE__), "ruck", "ugen", "wav")
require File.join(File.dirname(__FILE__), "ruck", "ugen", "oscillators")
