# run ex01.rb first (or, preferably, use way better input than ex01.wav)

=begin
https://lists.cs.princeton.edu/pipermail/chuck-users/2008-May/002983.html

> One way of subjectively "widening" a stereo image is to do the following:
> feed the left channel back to the right with a short delay, inverted;
> feed the right channel back to the left with a short delay, inverted;
=end

mix = 0.5

wavin = WavIn.new :filename => "ex01.wav", :gain => (1.0 - mix)
wavout = WavOut.new :filename => "ex09.wav", :num_channels => 2

wavin.out(0) >> (delayed_left =  Delay.new :time => 10.ms, :gain => mix)
wavin.out(1) >> (delayed_right = Delay.new :time => 10.ms, :gain => mix)
inverted_left = Step.new :value => L{ -delayed_left.next(now) }
inverted_right = Step.new :value => L{ -delayed_right.next(now) }

wavout >> blackhole
[wavin.out(0), inverted_right] >> wavout.in(0)
[wavin.out(1), inverted_left ] >> wavout.in(1)

play wavin.duration
puts "processed #{wavin.duration/SAMPLE_RATE} seconds"
