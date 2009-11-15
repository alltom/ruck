spoken = WavIn.new(:filename => "ex1.wav")
wav = WavOut.new(:filename => "ex6.wav")
spoken >> wav >> blackhole

(sin = SinOsc.new(:freq => 3, :gain => 0.1)) >> blackhole
spoken.rate = L{ 1.0 + sin.last }

play spoken.duration
