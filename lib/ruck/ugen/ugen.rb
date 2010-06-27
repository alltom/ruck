
# UGenShreduler (for scheduling shreds against the virtual
# clock of an audio file), and a framework for writing unit
# generators

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

end

# Allow chucking all elements of an array to
class Array
  include Ruck::Source
end
