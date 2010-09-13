
require "ruck"

include Ruck

class RealTimeShreduler < Shreduler
  def fast_forward(dt)
    super
    sleep(dt)
  end
end

@shreduler = RealTimeShreduler.new

@shreduler.shredule(Shred.new do
  %w{ A B C D E }.each do |letter|
    puts "#{letter}"
    @shreduler.shredule(Shred.current, @shreduler.now + 1)
    Shred.current.pause
  end
end)

@shreduler.shredule(Shred.new do
  %w{ 1 2 3 4 5 }.each do |number|
    puts "#{number}"
    @shreduler.shredule(Shred.current, @shreduler.now + 1)
    Shred.current.pause
  end
end)

@shreduler.run
