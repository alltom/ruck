# ruck: a port of ChucK's strong timing to Ruby!

ruck lets you create virtual timelines on which you can
precisely time the execution of events.

This is accomplished using Shred, Clock, and Shreduler:

- Shred: a resumable Proc (a Fiber wrapper on 1.9)
- Clock: manages objects on a timeline
- Shreduler: executes Shreds on time by managing them with a Clock

Here's an example of how to use Shred:

    shred = Ruck::Shred.new do
      puts "A"
      Ruck::Shred.current.pause
      puts "B"
      Ruck::Shred.current.pause
      puts "C"
    end
    
    shred.call
    shred.call
    shred.call
    
    # prints:
    # A
    # B
    # C

Here's how Clock works:

    clock = Ruck::Clock.new
    
    clock.schedule("C", 3)
    clock.schedule("B", 2)
    clock.schedule("A", 1)
    
    3.times do
      letter, time = clock.unschedule_next
      puts "#{letter} @ #{time}"
    end
    
    # prints:
    # A @ 1.0
    # B @ 2.0
    # C @ 3.0

Here's how these two are combined with Shreduler:

    @shreduler = Ruck::Shreduler.new
    
    @shreduler.shredule(Ruck::Shred.new do
      %w{ A B C D E }.each do |letter|
        puts "#{letter}"
        @shreduler.shredule(Ruck::Shred.current, @shreduler.now + 1)
        Ruck::Shred.current.pause
      end
    end)
    
    @shreduler.shredule(Ruck::Shred.new do
      %w{ 1 2 3 4 5 }.each do |number|
        puts "#{number}"
        @shreduler.shredule(Ruck::Shred.current, @shreduler.now + 1)
        Ruck::Shred.current.pause
      end
    end)
    
    @shreduler.run
    
    # prints
    # A
    # 1
    # B
    # 2
    # C
    # 3
    # D
    # 4
    # E
    # 5

Though this is somewhat inconvenient to use, so when you're
using just one global Shreduler, you can call
Shreduler#make_convenient, which adds useful methods to Object
and Shred so that you can write the above example more
concisely:

    @shreduler = Ruck::Shreduler.new
    @shreduler.make_convenient

    spork do
      %w{ A B C D E }.each do |letter|
        puts "#{letter}"
        Ruck::Shred.yield(1)
      end
    end

    spork do
      %w{ 1 2 3 4 5 }.each do |number|
        puts "#{number}"
        Ruck::Shred.yield(1)
      end
    end

    @shreduler.run

## Shredulers and time

ruck doesn't specify any behavior for when time passes,
so by default all shreds are executed as fast as possible
as they're drained from the queue. In other words, there's
no mapping from virtual time to anything else, so Shreduler
only really cares about order.

You change this by sub-classing Shreduler and overriding its
methods. For example, an easy modification is to map the
time units to seconds:

    class RealTimeShreduler < Ruck::Shreduler
      def fast_forward(dt)
        super
        sleep(dt)
      end
    end

## Useful Shredulers

These gems provide shredulers with other interesting mappings,
as well as defining convenient DSLs to make shreduling less
verbose:

<dl>
<dt>ruck-realtime</dt>
<dd>the above example</dd>

<dt>ruck-midi</dt>
<dd>maps to quarter notes in a MIDI file, quarter
notes in real-time, or both simultaneously (playing back,
then saving to disk)</dd>

<dt>ruck-ugen</dt>
<dd>maps to samples in an audio stream, providing a
simple unit generator framework for reading and writing WAV
files with effects</dd>
</dl>
