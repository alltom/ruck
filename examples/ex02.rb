
require "ruck"

include Ruck

class RealTimeShreduler < Shreduler
  def fast_forward(dt)
    super
    sleep(dt)
  end
end

@shreduler = RealTimeShreduler.new

@shreduler.shredule(Shred.new do |shred|
  %w{ A B C D E }.each do |letter|
    puts "#{letter}"
    @shreduler.shredule(shred, @shreduler.now + 1)
    shred.pause
  end
end)

@shreduler.shredule(Shred.new do |shred|
  %w{ 1 2 3 4 5 }.each do |number|
    puts "#{number}"
    @shreduler.shredule(shred, @shreduler.now + 1)
    shred.pause
  end
end)

@shreduler.run
