# ruck: a port of ChucK's strong timing to Ruby!

ruck lets you create virtual timelines on which you can
precisely time the execution of events.

This is accomplished using Shred, Clock, and Shreduler:

- Shred: a resumable Proc
- Clock: manages events on a timeline
- Shreduler: executes shreds on time

Here's an example of how to use Shred:

    shred = Shred.new do |shred|
      puts "A"
      shred.pause
      puts "B"
      shred.pause
      puts "C"
    end
    
    shred.call
    shred.call
    shred.call

Here's how Clock works:

    clock = Clock.new
    
    clock.schedule("C", 3)
    clock.schedule("B", 2)
    clock.schedule("A", 1)
    
    3.times do
      letter, time = clock.unschedule_next_event
      puts "#{letter} @ #{time}"
    end

Here's how these two are combined with Shreduler:

    @shreduler = Shreduler.new
    
    @shreduler.shredule(Shred.new do |shred|
      %w{ A B C D E }.each do |letter|
        puts "#{letter}"
        @shreduler.shredule(shred, @shreduler.now + 1)
        shred.pause
      end
    end)
    
    @shreduler.shredule(Shred.new do |shred|
      %w{ 1 2 3 4 5 }.each do |number|
        puts "#{number}"
        @shreduler.shredule(shred, @shreduler.now + 1)
        shred.pause
      end
    end)
    
    @shreduler.run

ruck doesn't specify any behavior for when time passes,
so by default all shreds are executed as fast as possible
as they're drained from the queue. In other words, there's
no mapping from virtual time to anything else, so Shreduler
only really cares about order.

You change this by sub-classes Shreduler and overriding its
methods. For example, an easy modification is to map the
time units to seconds:

    class RealTimeShreduler < Shreduler
      def fast_forward(dt)
        super
        sleep(dt)
      end
    end

These gems provide shredulers with other interesting mappings:

- ruck-realtime: the above example

- ruck-midi: maps to quarter notes in a MIDI file, quarter
  notes in real-time, or both simultaneously (playing back,
  then saving to disk)

- ruck-ugen: maps to samples in an audio stream, providing a
  simple unit generator framework for reading and writing WAV
  files with effects

- ruck-glapp: maps to real-time, but embedded in an OpenGL
  application
