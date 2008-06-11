spoken = WavIn.new("ex1.wav")
wav = WavOut.new("ex6.wav")
spoken >> wav >> dac

(sin = SinOsc.new(3, 0.1)) >> blackhole
spoken.rate = L{ 1.0 + sin.last }

play spoken.duration
