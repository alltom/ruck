
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

spork do
  loop do
    Shred.wait_on(:gogogo)
    puts "YEE HAW!"
    puts
  end
end

spork do
  loop do
    Shred.yield(1)
    puts "not yet"
    Shred.yield(1)
    puts "still not yet"
    Shred.yield(1)
    puts "okay now!"
    raise_event(:gogogo)
  end
end

@shreduler.run
