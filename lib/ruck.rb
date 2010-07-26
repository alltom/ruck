
module Ruck
  require "logger"
  LOG = Logger.new(STDOUT)
  LOG.level = Logger::WARN
end

require File.join(File.dirname(__FILE__), "ruck", "clock")
require File.join(File.dirname(__FILE__), "ruck", "event_clock")
require File.join(File.dirname(__FILE__), "ruck", "shreduler")
require File.join(File.dirname(__FILE__), "ruck", "shred")
