
# this example demonstrates Shreduler#make_convenient,
# which adds Object#spork and Shred#yield

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
  %w{ A B C D E }.each do |letter|
    puts "#{letter}"
    Shred.yield(1)
  end
end

spork do
  %w{ 1 2 3 4 5 }.each do |number|
    puts "#{number}"
    Shred.yield(1)
  end
end

@shreduler.run
