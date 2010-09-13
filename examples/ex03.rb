
require "rubygems"
require "midiator"
require "ruck"

include Ruck

def setup_midi
  midi = MIDIator::Interface.new
  # midi.autodetect_driver
  midi.use :dls_synth # OS X built-in synth

  midi.control_change 32, 10, 1 # TR-808 is Program 26 in LSB bank 1
  midi.program_change 10, 26
  
  include MIDIator::Drums
  
  midi
end

class RealTimeShreduler < Shreduler
  def fast_forward(dt)
    super
    sleep(dt)
  end
end



@midi = setup_midi
@shreduler = RealTimeShreduler.new

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
