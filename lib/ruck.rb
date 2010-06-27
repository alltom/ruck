
module Ruck
  require "logger"
  LOG = Logger.new(STDOUT)
  LOG.level = Logger::WARN
end

require File.join(File.dirname(__FILE__), "ruck", "shreduling")
require File.join(File.dirname(__FILE__), "ruck", "misc", "linkage")
