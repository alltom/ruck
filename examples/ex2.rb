require File.join(File.dirname(__FILE__), "..", "ruck")
include Ruck

spork do
  
  SinOsc.new(440) >> WavOut.new("ex2.wav") >> blackhole
  play 0.5.seconds

end

run
