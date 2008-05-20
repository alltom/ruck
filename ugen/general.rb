
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
      
      def next; 0; end
      def last; 0; end
    end
  
    class Gain
      include Source
      include Target
    
      def initialize(gain = 1.0)
        @gain = gain
        @ins = []
      end
  
      def next
        @ins.inject(0) { |samp, ugen| samp += ugen.next } * @gain
      end
    
      def to_s
        "<Gain: gain:#{@gain}>"
      end
    end
  
  end
end
