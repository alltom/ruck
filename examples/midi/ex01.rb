
def maybe
  rand >= 0.5
end

TRACKS[0].events << MIDI::Controller.new(10, 32, 1) # channel, controller, value
TRACKS[0].events << MIDI::ProgramChange.new(10, 26) # channel, program
MIDI_PLAYER.control_change 32, 10, 1 # number, channel, value
MIDI_PLAYER.program_change 10, 26 # channel, program

def play(note, dur = 1.quarter_note)
  return if maybe
  note_on note, 100, 10
  wait dur
  note_off note, 10
end

10.times do
  spork { play(rand(30) + 40, rand * 3.quarter_notes + 3.quarter_notes) }
  wait 0.5.quarter_note
end

wait 2.quarter_notes; note_off 0 # end padding

