# unlike the other examples, this one is meant to be executed stand-alone

# requires "midiator" gem
# tested on OS X

require "ruck"
require 'rubygems'
require 'midiator'

midi = MIDIator::Interface.new
midi.use :dls_synth
midi.instruct_user!

include MIDIator::Notes
scale = [ C4, Cs4, D4, Eb4, E4, F4, Fs4, G4, Gs4, A4, Bb4, B4,
          C5, Cs5, D5, Eb5, E5, F5, Fs5, G5, Gs5, A5, Bb5, B5 ]

@shreduler = Ruck::RealTimeShreduler.new

SAMPLE_RATE = 1

# As you can see below, things get a little messy without some
# nice helper methods. May I recommend you take a look at
# ruck_runner.rb

@shreduler.spork("main") do |main_shred|
  
  scale.each do |note|
    @shreduler.spork do |shred|
      midi.driver.note_on(note, 0, 100)
      shred.yield 5.second
      midi.driver.note_off(note, 0, 100)
    end
    
    main_shred.yield 0.4.seconds
  end
  
  main_shred.yield 2.second
  
  scale.reverse.each do |note|
    @shreduler.spork do |shred|
      midi.driver.note_on(note, 0, 100)
      shred.yield 5.second
      midi.driver.note_off(note, 0, 100)
    end
    
    main_shred.yield 0.2.seconds
  end
  
end

@shreduler.run

puts "done"
