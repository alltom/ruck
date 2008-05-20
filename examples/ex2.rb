require "../ruck"
include Ruck
include UGen

spork do
  
  wav = WavOut.new("test.wav")
  wav << SinOsc.new(440)
  blackhole << wav

  play 5.seconds

end

run
