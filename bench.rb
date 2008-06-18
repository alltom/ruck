TIME = 10 # seconds
count = 0
loop do
  SinOsc.new(:freq => 440) >> blackhole
  count += 1
  
  start = Time.now
  play TIME.seconds
  time = Time.now - start
  puts "at #{count}: #{time}"
  
  break if time > TIME
end
