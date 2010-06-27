# multi-channel WavOut

s1 = SinOsc.new :freq => 440
s2 = SinOsc.new :freq => 440 * 2
wav = WavOut.new :filename => "ex10.wav", :num_channels => 2
s1 >> wav.in(0)
s2 >> wav.in(1)
wav >> blackhole

play 3.seconds
