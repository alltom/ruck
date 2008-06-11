
module Riff
  
  class RiffReaderChunk
    attr_reader :data_start
    attr_accessor :data_skip
    
    def initialize(fn, start)
      @fn, @start = fn, start
      @size_start = @start + 4
      @data_start = @start + 8
      @data_skip = 0
    end
    
    def type
      return @type if @type
      @fn.seek @start
      @type = @fn.read(4)
    end
    
    def size
      return @size - @data_skip if @size
      @fn.seek @size_start
      @size = @fn.read(4).unpack("L")[0]
      @size - @data_skip
    end
    
    # pass a Range of bytes, or start and length
    def [](*args)
      first, last = case args.length
                    when 1; [args.first.begin, args.first.end]
                    when 2; [args[0], args[0] + args[1]]
                    end
      @fn.seek @data_start + @data_skip + first
      @fn.read(last - first + 1)
    end
    
    def chunks
      offset = @data_start + @data_skip
      chunks = []
      while offset + @data_skip - @data_start < size
        chunks << chunk = RiffReaderChunk.new(@fn, offset)
        offset += @data_start + chunk.size
      end
      chunks
    end
    
    def to_s
      "<RiffHeader type:#{type} size:#{size}>"
    end
    
  end

  class RiffReader
    def initialize(filename)
      @fn = File.open(filename, "rb")
    end
    
    def chunks
      offset = 0
      chunks = []
      until @fn.eof?
        chunks << chunk = RiffReaderChunk.new(@fn, offset)
        offset += 8 + chunk.size
        @fn.seek offset + 8
      end
      chunks
    end
  end
  
end
