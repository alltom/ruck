wav = WavOut.new(:filename => "ex3.wav")
s2 = SinOsc.new(:freq => 3)
s = SinOsc.new(:freq => L{ s2.last * 220 + 660 },
               :gain => L{ 0.5 + s2.last * 0.5 })

[s2, s >> wav] >> blackhole

play 3.seconds
