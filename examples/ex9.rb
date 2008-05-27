=begin
https://lists.cs.princeton.edu/pipermail/chuck-users/2008-May/002983.html

> One way of subjectively "widening" a stereo image is to do the following:
> feed the left channel back to the right with a short delay, inverted;
> feed the right channel back to the left with a short delay, inverted;
=end

# Well, we don't have stereo output yet
# But let's keep this around until ruck catches up

wav = WavOut.new("ex9.wav")
s = SinOsc.new(440, 0.5)
inverted = Step.new
delay = Delay.new(10.ms)
inverted.link_value L{ -delay.last }

# BUG: order of the next two lines matter;
#      otherwise, delay.last will be one sample off
#      (try setting delay to 0.samples)
s >> delay >> blackhole
[s, inverted] >> wav >> blackhole

# One day we'd hope to write instead
# [s >> delay, wav.all_channels] >> blackhole
# s >> wav.chan(0)
# inverted >> wav.chan(1)

play 3.seconds
