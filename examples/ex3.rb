(wav = WavOut.new("ex3.wav")) >> blackhole
(s = SinOsc.new(440, 0.5)) >> wav
(s2 = SinOsc.new(3)) >> blackhole

s.gain = L{ 0.5 + s2.last * 0.5 }
s.freq = L{ s2.last * 220 + 660 }

play 3.seconds
