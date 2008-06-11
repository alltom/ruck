SinOsc.new(:freq => 440) >> WavOut.new(:filename => "ex2.wav") >> blackhole
play 0.5.seconds
