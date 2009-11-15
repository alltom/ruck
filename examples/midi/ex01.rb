
TRACKS[0].name = "My New Track"
TRACKS[0].instrument = MIDI::GM_PATCH_NAMES[0]

def play(note, dur = 1.quarter_note)
  note_on note, 100
  wait dur
  note_off note
end

10.times do
  spork { play(rand(30) + 40, rand * 1.quarter_note + 1.quarter_note) }
  wait 0.5.quarter_note
end

wait 2.quarter_notes; note_off 0 # end padding

