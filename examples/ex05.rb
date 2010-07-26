
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

@event = EventClock.new
@shreduler.clock.add_child_clock(@event)

spork do |shred|
  loop do
    shred.yield(0, @event)
    puts "YEE HAW!"
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
    @event.raise_all
  end
end

@shreduler.run
