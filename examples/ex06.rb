# run ex01.rb first

spoken = WavIn.new(:filename => "ex01.wav")
wav = WavOut.new(:filename => "ex06.wav")
spoken.out(0) >> wav >> blackhole

(sin = SinOsc.new(:freq => 3, :gain => 0.1)) >> blackhole
spoken.rate = L{ 1.0 + sin.last }

play spoken.duration
