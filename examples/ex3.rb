wav = WavOut.new("ex3.wav")
s2 = SinOsc.new(3)
s = SinOsc.new(L{ s2.last * 220 + 660 }, L{ 0.5 + s2.last * 0.5 })

[s2, s >> wav] >> blackhole

play 3.seconds
