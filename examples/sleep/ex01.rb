spork("a") do
  loop do
    wait 1
    puts "second"
  end
end

spork("b") do
  loop do
    wait 0.5
    puts "       half-second"
  end
end
