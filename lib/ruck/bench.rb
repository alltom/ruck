
SAMPLE_RATE = 44100

if ARGV.include? "bench.rb"
  # benchmark UGens with shreduling

  TIME = 1.seconds
  count = 0
  puts "Simulating #{TIME / 1.second} seconds"
  loop do
    Step.new >> blackhole
    count += 1

    start = Time.now
    play TIME
    time = Time.now - start
    puts "#{count}: #{time}"

    break if time > (TIME / 1.second)
  end
else
  # benchmark UGens without shreduling

  require "../ruck"
  TIME = SAMPLE_RATE * 4
  dac = Ruck::InChannel.new
  count = 0
  @now = 0
  puts "Simulating #{TIME / SAMPLE_RATE} seconds"
  loop do
    Ruck::Generators::Step.new >> dac
    count += 1

    start = Time.now
    TIME.to_i.times do
      dac.next(@now)
      @now += 1
    end
    time = Time.now - start
    puts "#{count}: #{time}"

    break if time > (TIME / SAMPLE_RATE)
  end
end
