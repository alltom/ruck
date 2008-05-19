
module Ruck
  module UGen

    module Target
      def <<(ugen)
        @ins << ugen
      end
  
      def >>(ugen)
        @ins.delete(ugen)
      end
    end

    module Source
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
