
module Ruck
  module UGen

    module Oscillator
      def self.included(base)
        base.instance_eval do
          attr_accessor :freq
          attr_accessor :phase
        end
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
        @phase += @freq.to_f / SAMPLE_RATE.to_f
        samp
      end
  
      def to_s
        "<SinOsc: freq:#{@freq} gain:#{@gain}>"
      end
    end

  end
end
