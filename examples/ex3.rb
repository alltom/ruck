require File.join(File.dirname(__FILE__), "..", "ruck")
include Ruck

spork("main") do

  (wav = WavOut.new("ex3.wav")) >> blackhole
  (s = SinOsc.new(440, 0.5)) >> wav
  (s2 = SinOsc.new(3)) >> blackhole
  
  s.link_gain lambda { 0.5 + s2.last * 0.5 }
  s.link_freq lambda { s2.last * 220 + 660 }
  
  play 3.seconds

end

run
