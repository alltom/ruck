(wav = WavOut.new("ex4.wav")) >> blackhole
s = SawOsc.new(440, 0.5)
adsr = ADSR.new(50.ms, 1.0, 50.ms, 0.5, 1.second)
s >> adsr >> wav

play 1.second
adsr.on
play 2.seconds
adsr.off
play 2.seconds
