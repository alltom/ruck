
require File.join(File.dirname(__FILE__), "..", "misc", "riff")

module Ruck
  module UGen
    module Generators
    
      # saves all incoming samples in memory to export to disk later
      # outputs 0.0 samples
      class WavOut
        include UGenBase
        include Source
        include MultiChannelTarget

        attr_reader :filename

        def initialize(attrs = {})
          require_attrs attrs, [:filename]
          @filename = attrs.delete(:filename)
          @num_channels = attrs.delete(:num_channels) || 1
          @bits_per_sample = attrs.delete(:bits_per_sample) || 16
          parse_attrs attrs

          @in_channels = (1..@num_channels).map { InChannel.new }

          @sample_rate = SAMPLE_RATE
          @samples = (1..@num_channels).map { [] }
          @ins = []
          @last = 0.0

          # TODO: this is necessary, but if UGen graph were explicitly
          # destructed, that would be nice.
          at_exit { save }
        end

        def next(now)
          return @last if @now == now
          @now = now
          @samples << @in_channels.map { |chan| chan.next now }
          @last
        end

        def save
          LOG.info "Saving WAV to #{@filename}..."
          File.open(@filename, "wb") { |f| f.write encode }
        end

        def attr_names
          [:filename]
        end

        private

          def encode
            chunk("RIFF") do |riff|
              riff << ascii("WAVE")
              riff << chunk("fmt ") do |fmt|
                fmt << short(1) # format = 1: PCM (no compression)
                fmt << short(@num_channels)
                fmt << int(@sample_rate)
                fmt << int((@sample_rate * @num_channels * (@bits_per_sample / 8))) # byte-rate
                fmt << short((@num_channels * @bits_per_sample/8)) # block align
                fmt << short(@bits_per_sample) # bits/sample
              end
              riff << chunk("data") do |data|
                range = 2 ** (@bits_per_sample - 1)
                @samples.each do |sample_list|
                  sample_list.each { |sample| data << [sample * range].pack("s1") }
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
      class WavIn
        include UGenBase
        include MultiChannelSource

        linkable_attr :rate
        linkable_attr :gain
        attr_reader :filename

        def initialize(attrs = {})
          require_attrs attrs, [:filename]
          @rate = 1.0
          @gain = 1.0
          @filename = attrs.delete(:filename)
          parse_attrs attrs

          @loaded = false
          @playing = true

          init_wav
        end

        def init_wav
          riff = Riff::RiffReader.new(@filename).chunks.first
          unless riff.type == "RIFF"
            LOG.error "#{@filename}: Not RIFF!"
            return
          end
          unless riff[0..3] == "WAVE"
            LOG.error "#{@filename}: Not WAVE!"
            return
          end

          riff.data_skip = 4 # skip "WAVE"
          fmt = riff.chunks.first
          @wav = riff.chunks.find { |c| c.type == "data" }
          unless fmt[0..1].unpack("s1").first == 1
            LOG.error "#{@filename}: Not PCM!"
            return
          end

          @num_channels, @sample_rate, @byte_rate,
            @block_align, @bits_per_sample =
            fmt[2..15].unpack("s1i1i1s1s1")
          @range = (2 ** (@bits_per_sample - 1)).to_f

          @out_channels = (0..@num_channels-1).map { |chan| OutChannel.new self, chan }
          @sample = [0.0] * @num_channels
          @last = [0.0] * @num_channels
          @now = [nil] * @num_channels
          @rate_adjust = @sample_rate / SAMPLE_RATE

          @loaded = true
        end

        def duration
          @loaded ? @wav.size / @block_align / @rate_adjust : 0
        end

        def attr_names
          [:filename, :rate]
        end

        def next(now, chan = 0)
          return @last[chan] if @now[chan] == now
          @now[chan] = now

          return @last[chan] unless @loaded && @playing

          offset = @sample[chan].to_i * @block_align
          chan_offset = (chan * @bits_per_sample) / 8

          if offset + @block_align > @wav.size
            @playing = false
            return @last[chan]
          end

          @last[chan] = @wav[offset + chan_offset, @bits_per_sample].unpack("s1").first / @range * gain
          @sample[chan] += rate * @rate_adjust
          @last[chan]
        end

        def play; @playing = true; end
        def stop; @playing = false; end

        def reset
          @offset = 0
        end

      end
    
    end
  end
end
