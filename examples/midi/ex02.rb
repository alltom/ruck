
def maybe
  rand >= 0.5
end

@base = 43
@scale = 0
@chord = 0

major_scale = [0, 2, 4, 5, 7, 9, 11]
minor_scale = [0, 2, 3, 5, 7, 8, 11]
@scales = [major_scale, minor_scale]

def scale(note, scale)
  len = scale.length
  oct = note / len
  off = note % len
  while off < 0
    off += len
    oct -= 1
  end
  oct * 12 + scale[off]
end

def play(note, dur = 1.beat)
  midi_note = @base + scale(note, @scales[@scale])
  note_on midi_note, 100
  wait dur
  note_off midi_note
end

def change_chords
  loop do
    wait 4.beats
    @chord = rand(7)
    if rand <= 0.1
      @scale = (@scale + 1) % @scales.length
    end
  end
end

def play_chord(dur)
  spork { play(@chord, dur) }
  spork { play(@chord + 2, dur) }
  spork { play(@chord + 4, dur) }
end

def play_chords
  loop do
    if maybe && maybe
      play_chord 2.beats
      wait 2.beats
      play_chord 2.beats
      wait 2.beats
    else
      play_chord 4.beats
      wait 4.beats
    end
  end
end

def play_melody
  loop do
    len = ((rand(2) + 1) / 2.0).beats
    play(@chord + 7 + 2 * rand(4), len)
    wait len
  end
end

spork { change_chords }
spork { play_chords }
spork { play_melody }
