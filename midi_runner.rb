
require "ruck"

require "rubygems"
require "midilib"
require "midiator"

# configuration
if ARGV.length < 4
  puts "ruby midilib_runner.rb MIDI_FILENAME NUM_TRACKS LIVE SCRIPT_FILENAME [...]"
  exit 1
end

MIDI_FILENAME = ARGV[0]
NUM_TRACKS = ARGV[1].to_i
ALSO_LIVE = ["yes", "true", "1"].include? ARGV[2].downcase
FILENAMES = ARGV[3..-1]

class MIDIShreduler < Ruck::Shreduler
  def run
    @start_time = Time.now
    super
  end
  
  def sim_to(new_now)
    d = new_now - @now
    TRACK_DELTAS.each_with_index do |delta, i|
      TRACK_DELTAS[i] = delta + d
    end
    
    # sync with wall clock
    if ALSO_LIVE
      actual_now = Time.now
      simulated_now = @start_time + (new_now.to_f / SEQUENCE.ppqn / SEQUENCE.bpm * 60.0)
      if simulated_now > actual_now
        sleep(simulated_now - actual_now)
      end
    end
    
    @now = new_now
  end
end

# state
SHREDULER = MIDIShreduler.new
SEQUENCE = MIDI::Sequence.new
TRACKS = (1..NUM_TRACKS).map { MIDI::Track.new(SEQUENCE) }
TRACK_DELTAS = TRACKS.map { 0 }
if ALSO_LIVE
  MIDI_PLAYER = MIDIator::Interface.new
end

# midi initialization stuff
TRACKS.each do |track|
  SEQUENCE.tracks << track
  track.events << MIDI::Tempo.new(MIDI::Tempo.bpm_to_mpq(120))
  track.events << MIDI::MetaEvent.new(MIDI::META_SEQ_NAME, 'Sequence Name')
  track.events << MIDI::ProgramChange.new(0, 1, 0)
end
if ALSO_LIVE
  MIDI_PLAYER.use :dls_synth
  MIDI_PLAYER.instruct_user!
end

# set up some useful time helpers
module MIDITime
  def pulse
    self
  end
  alias_method :pulses, :pulse
  
  def quarter_note
    self * SEQUENCE.ppqn
  end
  alias_method :quarter_notes, :quarter_note
  alias_method :beat, :quarter_note
  alias_method :beats, :quarter_note
end

class Fixnum
  include MIDITime
end

class Float
  include MIDITime
end

# stuff accessible in a shred
module ShredLocal

  def now
    SHREDULER.now
  end

  def spork(name = "unnamed", &shred)
    SHREDULER.spork(name, &shred)
  end

  def wait(pulses)
    SHREDULER.current_shred.yield(pulses)
  end

  def finish
    shred = SHREDULER.current_shred
    SHREDULER.remove_shred shred
    shred.finish
  end
  
  def note_on(note, velocity = 127, channel = 0, track = 0)
    TRACKS[track].events << MIDI::NoteOnEvent.new(channel, note, velocity, TRACK_DELTAS[track].to_i)
    TRACK_DELTAS[track] = 0
    if ALSO_LIVE
      MIDI_PLAYER.driver.note_on(note, channel, velocity)
    end
  end
  
  def note_off(note, channel = 0, track = 0)
    TRACKS[track].events << MIDI::NoteOffEvent.new(channel, note, 0, TRACK_DELTAS[track].to_i)
    TRACK_DELTAS[track] = 0
    if ALSO_LIVE
      MIDI_PLAYER.driver.note_on(note, channel, 0)
    end
  end

end

FILENAMES.each do |filename|
  unless File.readable?(filename)
    LOG.fatal "Cannot read file #{filename}"
    exit
  end
end

FILENAMES.each do |filename|
  SHREDULER.spork(filename) do
    include ShredLocal
    require filename
  end
end

SHREDULER.run

File.open(MIDI_FILENAME, "wb") { |file| SEQUENCE.write(file) }
