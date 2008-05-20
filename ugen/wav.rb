
module Ruck
  module UGen
    
    class WavOut
      include Source
      include Target
  
      def initialize(filename)
        @sample_rate = SAMPLE_RATE
        @bits_per_sample = BITS_PER_SAMPLE
        @channels = CHANNELS
        @filename = filename
        @samples = []
        @ins = []
        
        at_exit { self.save }
      end
  
      def next
        n = @ins.inject(0) { |samp, ugen| samp += ugen.next }
        @samples << n
        n
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
              range = 2 ** (BITS_PER_SAMPLE - 1)
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

  end
end
