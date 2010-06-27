
module Ruck

  class UGenShreduler < Ruck::Shreduler
    def run
      super
    end

    def sim_to(new_now)
      while @now < new_now.to_i
        BLACKHOLE.next @now
        @now += 1
      end
    end
  end

  module UGen

    def to_s
      "<#{self.class}" +
        (name ? "(#{name})" : "") +
        " #{attr_names.map { |a| "#{a}:#{send a}" }.join " "}>"
    end

    attr_accessor :name

  protected

    def require_attrs(attrs, names)
      names.each do |name|
        unless attrs.has_key? name
          raise "#{self} requires attribute #{name}"
        end
      end
    end

    def parse_attrs(attrs)
      attrs.each do |attr, value|
        send("#{attr}=", value)
      end
    end

    def pop_attrs(attrs, names)
      names.map { |name| attrs.delete(name) }
    end

  end

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

  module MultiChannelTarget
    def add_source(ugen)
      if ugen.is_a? Array
        ugen.each { |u| add_source u }
        return self
      end
      
      if ugen.out_channels.length == 1
        @in_channels.each { |chan| chan.add_source ugen.out(0) }
      else
        1.upto([ugen.out_channels.length, @in_channels.length].min) do |i|
          @in_channels[i-1].add_source ugen.out(i-1)
        end
      end
      
      self
    end

    def remove_source(ugen)
      if ugen.is_a? Array
        ugen.each { |u| remove_source u }
        return
      end
      
      # remove all outputs of ugen from all inputs of self
      @in_channels.each do |in_chan|
        ugen.out_channels.each do |out_chan|
          in_chan.remove_source out_chan
        end
      end
      
      self
    end
    
    def in_channels
      @in_channels
    end

    def in(chan)
      @in_channels[chan]
    end
  end

  module Source
    def >>(ugen)
      ugen.add_source self
    end

    def <<(ugen)
      ugen.remove_source self
    end
    
    def out_channels
      [self]
    end

    def out(chan)
      self if chan == 0
    end

    def next(now); @last; end
    def last; @last; end
  end

  module MultiChannelSource
    def >>(ugen)
      ugen.add_source self
    end

    def <<(ugen)
      ugen.remove_source self
    end
    
    def out_channels
      @out_channels
    end
    
    def out(chan)
      @out_channels[chan]
    end

    def next(now, chan = 0); @last[chan]; end
    def last(chan = 0); @last[chan]; end
  end

  class InChannel
    include UGen
    include Target

    def initialize(attrs = {})
      parse_attrs attrs
      @ins = []
      @last = 0.0
    end

    def next(now)
      return @last if @now == now
      @now = now
      @last = @ins.inject(0) { |samp, ugen| samp += ugen.next(now) }
    end

    def attr_names
      []
    end
  end

  class OutChannel
    include Source

    def initialize(parent, channel_number)
      @parent = parent
      @channel_number = channel_number
    end

    def next(now)
      return @last if @now == now
      @last = @parent.next(now, @channel_number)
    end
  end

  module Generators
    
    class Gain
      include UGen
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
      include UGen
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
      include UGen
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
      include UGen
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
      include UGen
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
      include UGen
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

# Allow chucking all elements of an array to
class Array
  include Ruck::Source
end

# time helpers
module RuckTime
  def sample
    self
  end
  alias_method :samples, :sample
  
  def ms
    self.to_f * SAMPLE_RATE / 1000.0
  end
  
  def second
    self.to_f * SAMPLE_RATE
  end
  alias_method :seconds, :second
  
  def minute
    self.to_f * SAMPLE_RATE * 60.0
  end
  alias_method :minutes, :minute
end

class Fixnum
  include RuckTime
end

class Float
  include RuckTime
end
