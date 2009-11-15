def beep(wav, chan)
  (s = SawOsc.new(:freq => 440, :gain => 0.25)) >> wav.in(chan)
  10.times do
    play 0.1.seconds
    s.freq *= 1.2
  end
  s << wav
end

wav = WavOut.new(:filename => "ex01.wav", :num_channels => 2)
SinOsc.new(:freq => 440, :gain => 0.25) >> wav
SinOsc.new(:freq => 880, :gain => 0.25) >> wav

wav >> blackhole

chan = 0

10.times do
  play 0.7.seconds
  chan = (chan + 1) % 2
  spork("beep") { beep(wav, chan) }
end

play 2.seconds
