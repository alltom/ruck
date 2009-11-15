# when run with RealTimeShreduler, illustrates the passage of time

spork("a") do
  loop do
    play 1.second
    puts "second"
  end
end

spork("b") do
  loop do
    play 0.5.second
    puts "       half-second"
  end
end

while play 1.minute; end
