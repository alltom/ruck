
# basic unit generators

module Ruck
  
  module UGen
    
    module Generators
    
      class Gain
        include UGenBase
        include Source
        include Target

        linkable_attr :gain

        def initialize(attrs = {})
          parse_attrs({ :gain => 1.0 }.merge(attrs))
          @ins = []
          @last = 0.0
        end

        def next(now)
          return @last if @now == now
          @now = now
          @last = @ins.inject(0) { |samp, ugen| samp += ugen.next(now) } * gain
        end

        def attr_names
          [:gain]
        end
      end

      class Step
        include UGenBase
        include Source

        linkable_attr :value

        def initialize(attrs = {})
          parse_attrs({ :value => 0.0 }.merge(attrs))
          @last = value
        end

        def next(now)
          return @last if @now == now
          @now = now
          @last = value
        end

        def attr_names
          [:value]
        end
      end

      class Delay
        include UGenBase
        include Target
        include Source

        linkable_attr :gain

        def initialize(attrs = {})
          require_attrs attrs, [:time]
          samples = attrs.delete(:time)
          parse_attrs attrs
          @ins = []
          @last = 0.0
          @queue = [0.0] * samples
        end

        def next(now)
          return @last if @now == now
          @now = now

          @queue << @ins.inject(0) { |samp, ugen| samp += ugen.next(now) } * gain
          @last = @queue.shift
        end

        def attr_names
          [:time]
        end
      end

      class Noise
        include UGenBase
        include Source

        linkable_attr :gain

        def initialize(attrs = {})
          parse_attrs({ :gain => 1.0 }.merge(attrs))
          @last = 0.0
        end

        def next(now)
          return @last if @now == now
          @now = now
          @last = rand * gain
        end

        def attr_names
          [:gain]
        end
      end

      class Ramp
        include UGenBase
        include Source

        linkable_attr :from
        linkable_attr :to
        linkable_attr :duration
        linkable_attr :progress
        linkable_attr :paused

        def initialize(attrs = {})
          parse_attrs({ :from => 0.0,
                        :to => 1.0,
                        :duration => 1.second }.merge(attrs))
          @progress = 0.0
          @paused = false
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

        def attr_names
          [:from, :to, :duration, :progress, :paused]
        end

        protected

          def inc_progress
            return if @paused
            @progress += 1.0 / duration
            @progress = 1.0 if @progress > 1.0
          end

      end

      class ADSR
        include UGenBase
        include Target
        include Source

        attr_accessor :attack_time
        attr_accessor :attack_gain
        attr_accessor :decay_time
        attr_accessor :sustain_gain
        attr_accessor :release_time

        def initialize(attrs = {})
          parse_attrs({ :attack_time => 50.ms,
                        :attack_gain => 1.0,
                        :decay_time => 50.ms,
                        :sustain_gain => 0.5,
                        :release_time => 500.ms }.merge(attrs))

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

        def attr_names
          [:attack_time, :attack_gain, :decay_time, :sustain_gain, :release_time]
        end

      end
      
    end
    
  end
end
