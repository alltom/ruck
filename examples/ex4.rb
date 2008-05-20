require "../ruck"
include Ruck
include UGen

spork("main") do

  (wav = WavOut.new("test.wav")) >> blackhole
  (s = SawOsc.new(440, 0.5)) >> wav
  (adsr = ADSR.new(50.ms, 50.ms, 0.5, 1.second)) >> blackhole
  
  s.gain = Linkage.new(adsr, :last)
  
  play 1.second
  adsr.on
  play 2.seconds
  adsr.off
  play 2.seconds

end

run
