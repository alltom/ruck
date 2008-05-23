require "../ruck"
include Ruck
include UGen

spork do
  
  SinOsc.new(440) >> WavOut.new("test.wav") >> blackhole
  play 0.5.seconds

end

run
