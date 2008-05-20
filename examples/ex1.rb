require "../ruck"
include Ruck
include UGen

spork("main") do

  wav = WavOut.new("test.wav")
  wav << SinOsc.new(440, 0.3)
  wav << SinOsc.new(880, 0.3)

  blackhole << wav

  play 1.second

  spork("beep") { beep(wav) }

  5.times { play 2.seconds }

end

def beep(wav)
  wav << (s = SawOsc.new(440, 0.3))
  10.times do
    play 0.1.seconds
    s.freq *= 1.2
  end
  wav >> s
end

run
