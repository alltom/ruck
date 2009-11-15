
module Ruck
  require "logger"
  LOG = Logger.new(STDOUT)
  LOG.level = Logger::WARN
end

require File.join(File.dirname(__FILE__), "shreduling")
require File.join(File.dirname(__FILE__), "misc", "time")
require File.join(File.dirname(__FILE__), "misc", "metaid")
require File.join(File.dirname(__FILE__), "misc", "linkage")
require File.join(File.dirname(__FILE__), "ugen", "general")
require File.join(File.dirname(__FILE__), "ugen", "wav")
require File.join(File.dirname(__FILE__), "ugen", "oscillators")
