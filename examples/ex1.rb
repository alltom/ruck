def beep(wav)
  (s = SawOsc.new(:freq => 440, :gain => 0.25)) >> wav
  10.times do
    play 0.1.seconds
    s.freq *= 1.2
  end
  s << wav
end

wav = WavOut.new(:filename => "ex1.wav")
SinOsc.new(:freq => 440, :gain => 0.25) >> wav
SinOsc.new(:freq => 880, :gain => 0.25) >> wav

wav >> blackhole

play 1.second

spork("beep") { beep(wav) }

play 0.5.seconds

spork("beep") { beep(wav) }

3.times { play 1.seconds }
