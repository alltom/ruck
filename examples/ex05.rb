wav = WavIn.new(:filename => "ex1.wav")
wav >> WavOut.new(:filename => "ex05.wav") >> blackhole

wav.stop; play 0.5.seconds            # silence
wav.play; play 1.second     # play first second

(r = Ramp.new(:from => 1.0, :to => 2.0, :duration => 1.minute)) >> blackhole
wav.rate = L{ r.last }
play 3.seconds
