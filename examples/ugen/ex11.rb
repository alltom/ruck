# adds 60 Hz hum to a stereo wav file

wavin = WavIn.new :filename => "ex10.wav", :gain => 0.5
wavout = WavOut.new :filename => "ex11.wav", :num_channels => 2
wavin >> wavout
SinOsc.new(:freq => 60, :gain => 0.5) >> wavout
wavout >> blackhole

play 3.seconds
