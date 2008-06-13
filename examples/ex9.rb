=begin
https://lists.cs.princeton.edu/pipermail/chuck-users/2008-May/002983.html

> One way of subjectively "widening" a stereo image is to do the following:
> feed the left channel back to the right with a short delay, inverted;
> feed the right channel back to the left with a short delay, inverted;
=end

# Well, we don't have stereo output yet
# But let's keep this around until ruck catches up

wav = WavOut.new(:filename => "ex9.wav", :num_channels => 2)
s = SinOsc.new(:freq => 440, :gain => 0.5)

delayed = Delay.new(:time => 1.sample)
inverted = Step.new :value => L{ -delayed.next(now) }

[s, inverted] >> wav >> blackhole
s >> delayed >> blackhole

play 3.seconds
