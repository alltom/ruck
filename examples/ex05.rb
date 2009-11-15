wav = WavIn.new(:filename => "ex01.wav")
wav >> WavOut.new(:filename => "ex05.wav") >> blackhole

wav.play
play 1.second

(r = Ramp.new(:from => 1.0, :to => 2.0, :duration => 3.seconds)) >> blackhole
wav.rate = L{ r.last }
play 3.seconds
