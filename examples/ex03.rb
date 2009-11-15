wav = WavOut.new(:filename => "ex03.wav")
sin2 = SinOsc.new(:freq => 3)
sin = SinOsc.new(:freq => L{ sin2.last * 220 + 660 },
                 :gain => L{ 0.5 + sin2.last * 0.5 })

[sin >> wav, sin2] >> blackhole

play 3.seconds
