
require "rubygems"
require "midiator"
require "ruck"

include Ruck

def setup_midi
  midi = MIDIator::Interface.new
  # midi.autodetect_driver
  midi.use :dls_synth # OS X built-in synth
  
  include MIDIator::Drums
  
  midi
end

class RealTimeShreduler < Ruck::Shreduler
  def run
    @start_time = Time.now
    @simulated_now = 0
    super
  end
  
  def fast_forward(dt)
    super
    
    actual_now = Time.now - @start_time
    @simulated_now += dt
    if @simulated_now > actual_now
      sleep(@simulated_now - actual_now)
    end
  end
end


@midi = setup_midi
@shreduler = RealTimeShreduler.new
@shreduler.make_convenient

@scale = [0, 2, 4, 5, 7, 9, 11]
@base = 30
def to_scale(note)
  @base + @scale[note % @scale.length] + 12 * (note / @scale.length).to_i
end

spork_loop(0.2) do
  @midi.play([to_scale((rand * 21).to_i), to_scale((rand * 21).to_i)])
end

spork_loop do
  puts "major"
  # @base = 30
  @scale = [0, 2, 4, 5, 7, 9, 11]
  Shred.yield 5
  
  puts "minor"
  # @base = 32
  @scale = [0, 2, 3, 5, 7, 8, 11]
  Shred.yield 5
end

@shreduler.run

exit


@warped_clock = @shreduler.clock.add_child_clock(Clock.new)


# warped bass drum player
@shreduler.shredule(Shred.new do
  loop do
    @midi.note_on(BassDrum1, 10, 127)
    @midi.note_on(BassDrum1, 10, 127)
    
    @shreduler.shredule(Shred.current, @warped_clock.now + 1, @warped_clock)
    Shred.current.pause
  end
end, nil, @warped_clock)


# normal crash cymbal player
@shreduler.shredule(Shred.new do
  loop do
    @midi.note_on(CrashCymbal1, 10, 127)
    @midi.note_on(CrashCymbal1, 10, 127)
    
    @shreduler.shredule(Shred.current, @shreduler.now + 1)
    Shred.current.pause
  end
end)


# time warper
@shreduler.shredule(Shred.new do |shred|
  p = 0.0
  
  loop do
    bpm = Math.sin(p += 0.1) * 270.0 + 300.0
    @warped_clock.relative_rate = bpm / 60.0
    puts "#{bpm} bpm"
    
    @shreduler.shredule(Shred.current, @shreduler.now + 0.1)
    Shred.current.pause
  end
end)


@shreduler.run
