
module RuckTime
  def sample
    self.to_i
  end
  alias_method :samples, :sample
  
  def ms
    self * Ruck::SAMPLE_RATE / 1000.0
  end
  
  def second
    self * Ruck::SAMPLE_RATE
  end
  alias_method :seconds, :second
  
  def minute
    self * Ruck::SAMPLE_RATE * 60.0
  end
  alias_method :minutes, :minute
end

class Fixnum
  include RuckTime
end

class Float
  include RuckTime
end
