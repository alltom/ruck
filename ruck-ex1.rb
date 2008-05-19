require "ruck"
include Ruck

def beep(shred, wav)
  wav << (s = SinOsc.new(440, 0.3))
  shred.yield 1.second
  wav >> s
end

spork("main") do |shred|

  wav = WavOut.new("test.wav")
  wav << SinOsc.new(440, 0.3)
  wav << SinOsc.new(880, 0.3)

  blackhole << wav

  shred.yield 1.second

  spork("beep") do |x|
    wav << (s = SinOsc.new(440, 0.3))
    x.yield 1.second
    wav >> s
  end

  shred.yield 2.seconds
  
  wav.save
end

run
