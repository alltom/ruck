
module Ruck
  module UGen

    module Target
      def add_source(ugen)
        @ins << ugen
        self
      end
      
      def remove_source(ugen)
        @ins.delete(ugen)
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
          return if Linkage.is_link? @progress
          return if @paused
          @progress += 1.0 / duration
          @progress = 1.0 if @progress > 1.0
        end
      
    end
    
    class ADSR
      include Source
      
      attr_accessor :attack_time
      attr_accessor :decay_time
      attr_accessor :sustain_gain
      attr_accessor :release_time
      
      def initialize(attack_time, decay_time, sustain_gain, release_time)
        @attack_time = attack_time
        @decay_time = decay_time
        @sustain_gain = sustain_gain
        @release_time = release_time
        
        @ramp = Ramp.new
        
        @last = 0.0
        @state = :idle
      end
      
      def next
        @last = case @state
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
      end
      
      def on
        @ramp.reset
        @ramp.from, @ramp.to = @last, 1
        @ramp.duration = @attack_time
        @state = :attack
      end
      
      def off
        @ramp.reset
        @ramp.from, @ramp.to = @last, 0
        @ramp.duration = @release_time
        @state = :release
      end
      
    end
  
  end
end
