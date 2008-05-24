require File.join(File.dirname(__FILE__), "..", "ruck")
include Ruck

spork("main") do

  (wav = WavIn.new("ex1.wav")) >> WavOut.new("ex5.wav") >> blackhole
  play 0.5.seconds
  wav.play
  play 1.second
  wav.stop
  play 0.5.seconds
  wav.play
  play 4.seconds

end

run

