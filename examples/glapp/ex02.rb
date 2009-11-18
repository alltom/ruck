
require "rubygems"
require "midiator"

$midi = MIDIator::Interface.new
$midi.use :dls_synth
$midi.instruct_user!

def note_on(note, velocity = 127, channel = 0)
  $midi.driver.note_on(note, channel, velocity)
end

def note_off(note, channel = 0)
  $midi.driver.note_on(note, channel, 0)
end

spork do
  while ev = wait_for_key_down
    puts ev.inspect
    #note_on(ev.key)

    @stars << Star.new
    spork("star manager") do
      wait 3
      @stars.shift
    end
  end
end

spork do
  while ev = wait_for_key_up
    #note_off(ev.key)
  end
end

class Star
  def initialize
    @x = rand * 2 - 1
    @y = rand * 2 - 1
  end
  
  def draw
    glPushMatrix
      glTranslate @x, @y, -5
      glutSolidCube(0.1)
    glPopMatrix
  end
end

clear

@stars = []
while wait_for_frame
  clear
  @stars.each { |star| star.draw }
end
