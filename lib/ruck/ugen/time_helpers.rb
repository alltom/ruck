
# time helpers so you can write 4.seconds, 1.sample, etc

module RuckTime
  def sample
    self
  end
  alias_method :samples, :sample
  
  def ms
    self.to_f * SAMPLE_RATE / 1000.0
  end
  
  def second
    self.to_f * SAMPLE_RATE
  end
  alias_method :seconds, :second
  
  def minute
    self.to_f * SAMPLE_RATE * 60.0
  end
  alias_method :minutes, :minute
end

class Fixnum
  include RuckTime
end

class Float
  include RuckTime
end
