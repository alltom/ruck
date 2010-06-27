
module Ruck
  module RealTime
    class RealTimeShreduler < Shreduler
      def run
        @start_time = Time.now
        super
      end
  
      def sim_to(new_now)
        actual_now = Time.now
        simulated_now = @start_time + new_now.to_f
        if simulated_now > actual_now
          sleep(simulated_now - actual_now)
        end
    
        @now = new_now
      end
    end
  end
end
