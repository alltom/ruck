(wav = WavOut.new("ex4.wav")) >> blackhole
(s = SawOsc.new(440, 0.5)) >> wav
(adsr = ADSR.new(50.ms, 50.ms, 0.5, 1.second)) >> blackhole

s.link_gain lambda { adsr.last }

play 1.second
adsr.on
play 2.seconds
adsr.off
play 2.seconds
