
module Ruck
  module UGen

    module Oscillator
      def self.included(base)
        base.instance_eval do
          attr_accessor :freq
          attr_accessor :phase
        end
      end
      
      def phase_forward
        @phase = (@phase + @freq.to_f / SAMPLE_RATE.to_f) % 1.0
      end
    end

    class SinOsc
      include Source
      include Oscillator

      attr_accessor :gain

      def initialize(freq = 440.0, gain = 1.0)
        @freq = freq
        @gain = gain
        @phase = 0.0
      end

      def next
        samp = @gain * Math.sin(@phase * 2 * Math::PI)
        phase_forward
        samp
      end
  
      def to_s
        "<SinOsc: freq:#{@freq} gain:#{@gain}>"
      end
    end

    class SawOsc
      include Source
      include Oscillator

      attr_accessor :gain

      def initialize(freq = 440.0, gain = 1.0)
        @freq = freq
        @gain = gain
        @phase = 0.0
      end

      def next
        samp = if @phase < 0.5
          @phase * 4.0 - 1.0
        else
          1.0 - ((@phase - 0.5) * 4.0)
        end * @gain
        phase_forward
        samp
      end
  
      def to_s
        "<SawOsc: freq:#{@freq} gain:#{@gain}>"
      end
    end

  end
end
