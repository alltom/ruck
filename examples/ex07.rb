@bpm = 130.0
@one_beat = (1.0 / @bpm).minutes

(@wav = WavOut.new(:filename => "ex07.wav")) >> blackhole

def smash(len = @one_beat)
  (n = Noise.new(:gain => 0.4)) >> (a = ADSR.new) >> @wav
  a.release_time = len
  a.on; play @one_beat / 1.5
  a.off; play len
  a << @wav
end

def beat
  (thump = SawOsc.new(:freq => 220, :gain => 0.7)) >> (a = ADSR.new) >> @wav
  a.on; play @one_beat / 2.0
  a.off; play a.release_time
  a << @wav
end

4.times do
  spork("beat 1") { beat }; spork("smash") { smash }
  play @one_beat

  spork("beat 2") { beat }
  play @one_beat

  spork("beat 3") { beat }
  play @one_beat

  spork("beat 4") { beat }
  play @one_beat
end

smash(5.seconds)
