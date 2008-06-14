=begin
https://lists.cs.princeton.edu/pipermail/chuck-users/2008-May/002983.html

> One way of subjectively "widening" a stereo image is to do the following:
> feed the left channel back to the right with a short delay, inverted;
> feed the right channel back to the left with a short delay, inverted;
=end

wavin = WavIn.new :filename => "ex1.wav"
wavout = WavOut.new :filename => "ex9.wav", :num_channels => 2

delayed_left = Delay.new(:time => 15.ms)
delayed_right = Delay.new(:time => 15.ms)
inverted_left = Step.new :value => L{ -delayed_right.next(now) }
inverted_right = Step.new :value => L{ -delayed_left.next(now) }

wavout >> blackhole
[wavin.out(0), inverted_right] >> wavout.in(0)
[wavin.out(1), inverted_left] >> wavout.in(1)

play wavin.duration
