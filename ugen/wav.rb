
module Ruck
  
  # saves sound passed in to export to file later
  # passes sound through live
  class WavOut
    include UGen
    include Source
    include Target

    def initialize(attrs = {})
      require_attrs attrs, [:filename]
      @filename = attrs.delete(:filename)
      parse_attrs attrs
      @now = 0
      @sample_rate = SAMPLE_RATE
      @bits_per_sample = BITS_PER_SAMPLE
      @channels = CHANNELS
      @samples = []
      @ins = []
      @last = 0.0
      
      at_exit { self.save }
    end

    def next(now)
      return @last if @now == now
      @now = now
      @last = @ins.inject(0) { |samp, ugen| samp += ugen.next(now) }
      @samples << @last
      @last
    end

    def save
      puts "Saving WAV to #{@filename}..."
      File.open(@filename, "wb") { |f| f.write encode }
    end

    def to_s
      "<WavOut: filename:#{@filename}>"
    end

    private

      def encode
        range = 2 ** (BITS_PER_SAMPLE - 1)
        chunk("RIFF") do |riff|
          riff << ascii("WAVE")
          riff << chunk("fmt ") do |fmt|
            fmt << short(1) # format = 1: PCM (no compression)
            fmt << short(@channels) # num channels
            fmt << int(@sample_rate)
            fmt << int((@sample_rate * @channels * (@bits_per_sample / 8))) # byte-rate
            fmt << short((@channels * @bits_per_sample/8)) # block align
            fmt << short(@bits_per_sample) # bits/sample
          end
          riff << chunk("data") do |data|
            @samples.each do |sample|
              data << [sample * range].pack("s1")
            end
          end
        end
      end

      def int(i)
        [i].pack("i1")
      end

      def short(s)
        [s].pack("s1")
      end

      def ascii(str)
        str.split("").pack("A1" * str.length)
      end

      def chunk(type, &block)
        buf = ""
        block.call(buf)
        ascii(type) + int(buf.length) + buf
      end

  end
  
  # plays sound stored in a RIFF WAV file
  # bugs:
  # - assumes sample rate matches ours
  # - no way to chuck any channel but the first
  class WavIn
    include UGen
    include Source
    
    linkable_attr :rate
    
    def initialize(attrs = {})
      require_attrs attrs, [:filename]
      @filename = attrs.delete(:filename)
      parse_attrs attrs
      
      @now = 0
      @sample = 0.0
      @samples = []
      @ins = []
      @last = 0.0
      @rate = 1.0
      @loaded = false
      @playing = true
      
      init_wav
    end
    
    def init_wav
      riff = Riff::RiffReader.new(@filename).chunks.first
      unless riff.type == "RIFF"
        $stderr.puts "#{@filename}: Not RIFF!"
        return
      end
      unless riff[0..3] == "WAVE"
        $stderr.puts "#{@filename}: Not WAVE!"
        return
      end
      
      riff.data_skip = 4 # skip "WAVE"
      fmt, @wav = riff.chunks
      unless fmt[0..1].unpack("s1").first == 1
        $stderr.puts "#{@filename}: Not PCM!"
        return
      end
      
      @channels, @sample_rate, @byte_rate,
        @block_align, @bits_per_sample =
        fmt[2..15].unpack("s1i1i1s1s1")
      @range = (2 ** (@bits_per_sample - 1)).to_f
      
      @loaded = true
    end
    
    def duration
      @loaded ? @wav.size / @block_align : 0
    end
    
    def next(now, chan = 0)
      return @last if @now == now
      @now = now
      
      return @last unless @loaded && @playing
      
      offset = @sample.to_i * @block_align
      chan_offset = chan * @bits_per_sample
      
      if offset + @block_align > @wav.size
        @playing = false
        return @last
      end
      
      @last = @wav[offset + chan_offset, @bits_per_sample].unpack("s1").first / @range
      @sample += rate
      @last
    end
    
    def play; @playing = true; end
    def stop; @playing = false; end
    
    def reset
      @offset = 0
    end
    
  end

end

require File.join(File.dirname(__FILE__), "..", "misc", "riff")
