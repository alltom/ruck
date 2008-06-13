
module Ruck

  module UGen
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

    def to_s
      "<#{self.class} #{attr_names.map { |a| "#{a}:#{send a}" }.join " "}>"
    end

    attr :name
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
      @channels.each { |chan| chan.add_source ugen }
    end

    def remove_source(ugen)
      @channels.each { |chan| chan.remove_source ugen }
    end

    def chan(num)
      @channels[num]
    end

    def channels
      @channels.dup
    end

    def num_channels
      @channels.length
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

  class Bus
    include UGen
    include Source
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

  class DAC
    include UGen
    include MultiChannelTarget

    def initialize(attrs = {})
      require_attrs attrs, [:num_channels]
      num_channels = attrs.delete(:num_channels)
      parse_attrs attrs
      @channels = (1..num_channels).map { Bus.new }
    end

    def attr_names
      [:num_channels]
    end
  end

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

      @queue << @ins.inject(0) { |samp, ugen| samp += ugen.next(now) }
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

# Allow chucking all elements of an array to
class Array
  include Ruck::Source
end
