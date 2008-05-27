
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
    
    def next; @last; end
    def last; @last; end
  end

  class Gain
    include Source
    include Target
    
    linkable_attr :gain
  
    def initialize(gain = 1.0)
      @gain = gain
      @ins = []
      @last = 0.0
    end

    def next
      @last = @ins.inject(0) { |samp, ugen| samp += ugen.next } * gain
    end
  
    def to_s
      "<Gain: gain:#{gain}>"
    end
  end

  class Step
    include Source
    
    linkable_attr :value
  
    def initialize(value = 0.0)
      @last = value
    end

    def next
      @last = value
    end
  
    def to_s
      "<Step: value:#{value}>"
    end
  end
  
  class Noise
    include Source
    
    linkable_attr :gain
    
    def initialize(gain = 1.0)
      @gain = gain
      @last = 0.0
    end
    
    def next
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
      @from = from
      @to = to
      @duration = duration
      @paused = false
      @progress = 0.0
      @last = 0.0
    end
    
    def next
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
    
    def next
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
                @ramp.next
              when :decay
                @state = :sustain if @ramp.finished?
                @ramp.next
              when :sustain
                @sustain_gain
              when :release
                @state = :idle if @ramp.finished?
                @ramp.next
              end
      @last = @ins.inject(0) { |samp, ugen| samp += ugen.next } * @gain
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
      self.base_freq = base_freq
      self.num_harmonics = num_harmonics
      self.gain = gain
      
      @last = 0.0
    end
    
    def next
      @last = @oscillators.inject(0) { |samp, sin| samp += sin.next } * gain
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
      @ins = []
      @last = 0.0
    end
    
    def next
      @last = (@last + @ins.inject(0) { |samp, ugen| samp += ugen.next }) / 2.0
    end
    
    def to_s
      "<LowPass>"
    end
    
  end
  
end
  
class Array
  include Ruck::Source
end
