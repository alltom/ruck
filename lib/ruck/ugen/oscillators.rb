
# a bunch of oscillating unit generators (SinOsc,
# SawOsc, TriOsc) and their base class, Oscillator

module Ruck
  
  module UGen
    
    module Oscillator
      include UGenBase
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
  
    module Generators
    
      class SinOsc
        include Source
        include Oscillator

        linkable_attr :freq
        linkable_attr :gain

        def initialize(attrs = {})
          parse_attrs({ :freq => 440.0,
                        :gain => 1.0 }.merge(attrs))
          @phase = 0.0
          @last = 0.0
        end

        def next(now)
          return @last if @now == now
          @now = now
          @last = gain * Math.sin(phase * TWO_PI)
          phase_forward
          @last
        end
    
        def attr_names
          [:freq, :gain, :phase]
        end
      end

      class SawOsc
        include Source
        include Oscillator

        linkable_attr :gain

        def initialize(attrs = {})
          parse_attrs({ :freq => 440.0,
                        :gain => 1.0 }.merge(attrs))
          @phase = 0.0
          @last = 0.0
        end

        def next(now)
          return @last if @now == now
          @now = now
          @last = ((phase * 2.0) - 1.0) * gain
          phase_forward
          @last
        end
    
        def attr_names
          [:freq, :gain, :phase]
        end
      end

      class TriOsc
        include Source
        include Oscillator

        linkable_attr :gain

        def initialize(attrs = {})
          parse_attrs({ :freq => 440.0,
                        :gain => 1.0 }.merge(attrs))
          @phase = 0.0
          @last = 0.0
        end

        def next(now)
          return @last if @now == now
          @now = now
          @last = if phase < 0.5
            phase * 4.0 - 1.0
          else
            1.0 - ((phase - 0.5) * 4.0)
          end * gain
          phase_forward
          @last
        end
    
        def attr_names
          [:freq, :gain, :phase]
        end
      end
    
    end
    
  end
  
end
