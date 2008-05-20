require "../ruck"
include Ruck
include UGen

spork do
  
  blackhole << WavOut.new("test.wav") << SinOsc.new(440)
  play 5.seconds

end

run
