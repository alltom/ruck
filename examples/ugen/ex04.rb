(wav = WavOut.new(:filename => "ex04.wav")) >> blackhole
s = SawOsc.new(:freq => 440, :gain => 0.5)
adsr = ADSR.new(:attack_time => 50.ms,
                :attack_gain => 1.0,
                :decay_time => 50.ms,
                :sustain_gain => 0.5,
                :release_time => 1.second)
s >> adsr >> wav

play 1.second
adsr.on
play 2.seconds
adsr.off
play 2.seconds
