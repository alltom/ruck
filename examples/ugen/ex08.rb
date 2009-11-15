# An experiment with formants
# http://en.wikipedia.org/wiki/Formant

wav = WavOut.new(:filename => "ex08.wav")
ramps = (1..4).map { Ramp.new(:duration => 50.ms) }
oscillators = (1..4).map { SinOsc.new }
[oscillators >> wav, ramps] >> blackhole

(0..3).each { |i| oscillators[i].freq = L{ ramps[i].last } }

#vowel_ah = [1000, 1400]
#vowel_eh = [500, 2300]
#vowel_oh = [500, 1000]
vowel_ee = [[320, 1.0], [2500, 1.0], [3200, 1.0], [4600, 0.6]]
vowel_oo = [[320, 1.0], [800, 0.3], [2500, 0.1], [3300, 0.1]]

5.times do
  [vowel_ee, vowel_oo].each do |vowel|
    puts "doing #{vowel.inspect}"
    (0..3).each do |i|
      ramps[i].reset
      ramps[i].from = ramps[i].to
      ramps[i].to = vowel[i].first
      oscillators[i].gain = vowel[i].last / 4.0
    end
    play 1.second
  end
end
