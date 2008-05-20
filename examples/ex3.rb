require "../ruck"
include Ruck
include UGen

spork("main") do

  (wav = WavOut.new("test.wav")) >> blackhole
  (s = SinOsc.new(440, 0.5)) >> wav
  (s2 = SinOsc.new(1)) >> blackhole
  
  s.freq = Linkage.new(s2, :last, :scale => [(-1..1), (440..880)])
  s.gain = Linkage.new(s2, :last, :scale => [(-1..1), (0..1)])
  
  play 3.seconds

end

run
