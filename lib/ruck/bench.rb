
puts "Testing how many Step ugens it takes to synthesize slower than real-time"

seconds = 4

# were we invoked as a ruck_ugen script, or stand-alone?
if __FILE__ == $0
  # we were invoked like "ruby bench.rb"
  # benchmark UGens without shreduling
  
  puts "... without shreduling"

  require "ruck"
  require "ruck/ugen"
  
  SAMPLE_RATE = 22050
  TIME = SAMPLE_RATE * seconds
  dac = Ruck::InChannel.new
  count = 0
  @now = 0
  puts "Simulating #{TIME / SAMPLE_RATE} seconds at #{SAMPLE_RATE} sample rate"
  loop do
    Ruck::Generators::Step.new >> dac
    count += 1

    start = Time.now
    TIME.to_i.times do
      dac.next(@now)
      @now += 1
    end
    
    time = Time.now - start
    puts "#{count} ugens took #{time} sec to synthesize #{TIME / 1.seconds} sec"

    break if time > (TIME / SAMPLE_RATE)
  end
else
  # we were invoked by ruck_ugen
  # benchmark UGens with shreduling
  
  puts "... with shreduling"

  TIME = seconds.seconds
  count = 0
  puts "Simulating #{TIME / 1.second} seconds at #{SAMPLE_RATE} sample rate"
  loop do
    Step.new >> blackhole
    count += 1

    start = Time.now
    play TIME
    time = Time.now - start
    puts "#{count} ugens took #{time} sec to synthesize #{TIME / 1.seconds} sec"

    break if time > (TIME / 1.second)
  end
end
