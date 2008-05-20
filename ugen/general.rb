
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
  
  end
end
