
require "ruck"

include Ruck

class RealTimeShreduler < Shreduler
  def fast_forward(dt)
    super
    sleep(dt)
  end
end

@shreduler = RealTimeShreduler.new
@shreduler.make_convenient

spork do |shred|
  loop do
    shred.wait_on(:gogogo)
    puts "YEE HAW!"
    puts
  end
end

spork do |shred|
  loop do
    shred.yield(1)
    puts "not yet"
    shred.yield(1)
    puts "still not yet"
    shred.yield(1)
    puts "okay now!"
    raise_event(:gogogo)
  end
end

@shreduler.run
