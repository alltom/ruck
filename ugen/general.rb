
module Ruck

  module Target
    def add_source(ugen)
      if ugen.is_a? Array
        ugen.each { |u| add_source u }
      else
        @ins << ugen
      end
      self
    end
    
    def remove_source(ugen)
      if ugen.is_a? Array
        ugen.each { |u| remove_source u }
      else
        @ins.delete(ugen)
      end
      self
    end
  end

  module Source
    def >>(ugen)
      ugen.add_source self
    end
    
    def <<(ugen)
      ugen.remove_source self
    end
    
    def next(now); @last; end
    def last; @last; end
  end

  class Gain
    include Source
    include Target
    
    linkable_attr :gain
  
    def initialize(gain = 1.0)
      @now = 0
      @gain = gain
      @ins = []
      @last = 0.0
    end

    def next(now)
      return @last if @now == now
      @now = now
      @last = @ins.inject(0) { |samp, ugen| samp += ugen.next(now) } * gain
    end
  
    def to_s
      "<Gain: gain:#{gain}>"
    end
  end

  class Step
    include Source
    
    linkable_attr :value
  
    def initialize(value = 0.0)
      @now = 0
      @last = value
    end

    def next(now)
      return @last if @now == now
      @now = now
      @last = value
    end
  
    def to_s
      "<Step: value:#{value}>"
    end
  end

  class Delay
    include Target
    include Source
  
    def initialize(samples)
      @now = 0
      @ins = []
      @last = 0.0
      
      @queue = [0.0] * samples
    end

    def next(now)
      return @last if @now == now
      @now = now
      
      @queue << @ins.inject(0) { |samp, ugen| samp += ugen.next(now) }
      @last = @queue.shift
    end
  
    def to_s
      "<Step: value:#{value}>"
    end
  end
  
  class Noise
    include Source
    
    linkable_attr :gain
    
    def initialize(gain = 1.0)
      @now = 0
      @gain = gain
      @last = 0.0
    end
    
    def next(now)
      return @last if @now == now
      @now = now
      @last = rand * gain
    end
    
    def to_s
      "<Noise: gain:#{gain}>"
    end
  end
  
  class Ramp
    include Source
    
    linkable_attr :from
    linkable_attr :to
    linkable_attr :duration
    linkable_attr :progress
    linkable_attr :paused
    
    def initialize(from = 0.0, to = 1.0, duration = 1.second)
      @now = 0
      @from = from
      @to = to
      @duration = duration
      @paused = false
      @progress = 0.0
      @last = 0.0
    end
    
    def next(now)
      return @last if @now == now
      @now = now
      @last = progress * (to - from) + from
      inc_progress
      @last
    end
    
    def reverse
      @from, @to = @to, @from
    end
    
    def reset
      @progress = 0.0
    end
    
    def finished?
      progress == 1.0
    end
    
    protected
    
      def inc_progress
        return if @paused
        @progress += 1.0 / duration
        @progress = 1.0 if @progress > 1.0
      end
    
  end
  
  class ADSR
    include Target
    include Source
    
    attr_accessor :attack_time
    attr_accessor :attack_gain
    attr_accessor :decay_time
    attr_accessor :sustain_gain
    attr_accessor :release_time
    
    def initialize(attack_time = 50.ms,
                   attack_gain = 1.0,
                   decay_time = 50.ms,
                   sustain_gain = 0.5,
                   release_time = 500.ms)
      @now = 0
      @attack_time = attack_time
      @attack_gain = attack_gain
      @decay_time = decay_time
      @sustain_gain = sustain_gain
      @release_time = release_time
      
      @ramp = Ramp.new
      
      @ins = []
      @last = 0.0
      @gain = 0.0
      @state = :idle
    end
    
    def next(now)
      return @last if @now == now
      @now = now
      @gain = case @state
              when :idle
                0
              when :attack
                if @ramp.finished?
                  @ramp.reset
                  @ramp.from, @ramp.to = @ramp.last, @sustain_gain
                  @ramp.duration = @decay_time
                  @state = :decay
                end
                @ramp.next(now)
              when :decay
                @state = :sustain if @ramp.finished?
                @ramp.next(now)
              when :sustain
                @sustain_gain
              when :release
                @state = :idle if @ramp.finished?
                @ramp.next(now)
              end
      @last = @ins.inject(0) { |samp, ugen| samp += ugen.next(now) } * @gain
    end
    
    def on
      @ramp.reset
      @ramp.from, @ramp.to = @gain, @attack_gain
      @ramp.duration = @attack_time
      @state = :attack
    end
    
    def off
      @ramp.reset
      @ramp.from, @ramp.to = @gain, 0
      @ramp.duration = @release_time
      @state = :release
    end
    
  end
  
  class Harmonics
    include Source
    
    linkable_attr :base_freq
    linkable_attr :gain
    attr_reader :num_harmonics
    
    # gain is split among the harmonics according to proportions
    # gain_proportions is normalized
    def initialize(base_freq, num_harmonics, gain = 1.0)
      @now = 0
      self.base_freq = base_freq
      self.num_harmonics = num_harmonics
      self.gain = gain
      
      @last = 0.0
    end
    
    def next(now)
      return @last if @now == now
      @now = now
      @last = @oscillators.inject(0) { |samp, sin| samp += sin.next(now) } * gain
    end
    
    def num_harmonics=(new_num)
      @num_harmonics = new_num
      @oscillators = (1..@num_harmonics).map { |num|
        SinOsc.new(base_freq * num, 1.0 / @num_harmonics)
      }
      @num_harmonics
    end
    
    def to_s
      "<Harmonics: base_freq:#{base_freq} gain:#{gain} num_harmonics:#{num_harmonics}"
    end
    
  end
  
  class LowPass
    include Target
    include Source
    
    def initialize
      @now = 0
      @ins = []
      @last = 0.0
    end
    
    def next(now)
      return @last if @now == now
      @now = now
      @last = (@last + @ins.inject(0) { |samp, ugen| samp += ugen.next(now) }) / 2.0
    end
    
    def to_s
      "<LowPass>"
    end
    
  end
  
end

# Allow chucking all elements of an array to 
class Array
  include Ruck::Source
end
