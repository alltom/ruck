
module Ruck
    
  module Oscillator
    TWO_PI = 2 * Math::PI
    
    def self.included(base)
      base.instance_eval do
        linkable_attr :freq
        linkable_attr :phase
      end
    end
    
    def phase_forward
      @phase = (@phase + freq.to_f / SAMPLE_RATE.to_f) % 1.0
    end
  end

  class SinOsc
    include Source
    include Oscillator

    linkable_attr :gain

    def initialize(freq = 440.0, gain = 1.0)
      @freq = freq
      @gain = gain
      @phase = 0.0
      @last = 0.0
    end

    def next
      @last = gain * Math.sin(phase * TWO_PI)
      phase_forward
      @last
    end

    def to_s
      "<SinOsc: freq:#{freq} gain:#{gain}>"
    end
  end

  class SawOsc
    include Source
    include Oscillator

    linkable_attr :gain

    def initialize(freq = 440.0, gain = 1.0)
      @freq = freq
      @gain = gain
      @phase = 0.0
      @last = 0.0
    end

    def next
      @last = ((phase * 2.0) - 1.0) * gain
      phase_forward
      @last
    end

    def to_s
      "<SawOsc: freq:#{freq} gain:#{gain}>"
    end
  end

  class TriOsc
    include Source
    include Oscillator

    linkable_attr :gain

    def initialize(freq = 440.0, gain = 1.0)
      @freq = freq
      @gain = gain
      @phase = 0.0
      @last = 0.0
    end

    def next
      @last = if phase < 0.5
        phase * 4.0 - 1.0
      else
        1.0 - ((phase - 0.5) * 4.0)
      end * gain
      phase_forward
      @last
    end

    def to_s
      "<TriOsc: freq:#{freq} gain:#{gain}>"
    end
  end

end
