SinOsc.new(:freq => 440) >> WavOut.new(:filename => "ex02.wav") >> blackhole
play 3.seconds
