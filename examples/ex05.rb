
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

spork_loop(:gogogo) do
  puts "YEE HAW!"
  puts
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
