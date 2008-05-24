require File.join(File.dirname(__FILE__), "..", "ruck")
include Ruck

spork do

  (wav = WavIn.new("ex1.wav")) >> WavOut.new("ex5.wav") >> blackhole
  play 0.5.seconds            # silence
  wav.play; play 1.second     # play first second
  
  (r = Ramp.new(1.0, 2.0, 1.minutes)) >> blackhole
  wav.link_rate lambda { r.last }
  play 3.seconds

end

run

