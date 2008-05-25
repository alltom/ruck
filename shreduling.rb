
module Ruck
  
  class Shred
    attr_reader :now
    attr_accessor :finished
    
    def initialize(shreduler, now, name, &block)
      @shreduler = shreduler
      @now = now
      @name = name
      @block = block
      @finished = false
    end
    
    def go(resume)
      @resume = resume
      @block.call
      @finished = true
    end
    
    def yield(samples)
      samples = samples.to_i
      samples = 0 if samples < 0
      @now += samples
      callcc do |cont|
        @block = cont
        @resume.call # jump back to shreduler
      end
      samples
    end
    
    def <=>(shred)
      @now <=> shred.now
    end
    
    def to_s
      "<Shred: #{@name}>"
    end
  end
  
  class Shreduler
    attr_reader :running
    attr_reader :current_shred
    
    def initialize
      @shreds = []
      @now = 0
      @running = false
    end
    
    def spork(name, &shred)
      puts "Adding shred \"#{name}\" at #{@now}"
      @shreds << Shred.new(self, @now, name, &shred)
    end
    
    def sim
      min = @shreds.min
      min_now = min.now
      @dac = dac
      (min_now - @now).times do
        @dac.next
        @now += 1
      end
      @now = min_now
      min
    end
    
    def run
      puts "shreduler starting"
      @running = true
      
      while @shreds.length > 0
        @current_shred = sim
        callcc { |cont| @current_shred.go(cont) }
        if @current_shred.finished
          puts "#{@current_shred} finished"
          @shreds.delete(@current_shred)
        end
      end
      
      @running = false
    end
  end
  
end