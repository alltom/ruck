require "../ruck"
include Ruck
include UGen

spork("main") do |shred|

  wav = WavOut.new("test.wav")
  wav << SinOsc.new(440, 0.3)
  wav << SinOsc.new(880, 0.3)

  blackhole << wav

  shred.yield 1.second

  spork("beep") { |shred| beep(shred, wav) }

  shred.yield 2.seconds
  
  wav.save
end

def beep(shred, wav)
  puts "beep is in #{shred}"
  wav << (s = SawOsc.new(440, 0.3))
  10.times do
    shred.yield 0.1.seconds
    s.freq *= 1.2
  end
  wav >> s
end

run
