# The goal of linkages is to have attributes which are
# periodically re-evaluated. Basically, to turn this:
# 
#   loop { ugen.gain = abs(sin.last); play 1.sample }
# 
# into this:
# 
#   ugen.gain = Linkage.new(sin, :last)
#   loop { play 10.seconds }
# 
# The way I do this now (check for Linkage in the
# attribute read method) is really slow. Gotta be
# a better way.

module Ruck
  
  class Linkage
    def initialize(object, method, options = {})
      @object = object
      @method = method
      @scale = options[:scale]
    end

    def real_value
      val = @object.send(@method)
      if @scale
        from, to = @scale
        range = (val - from.begin) / (from.end - from.begin)
        val = range * (to.end - to.begin) + to.begin
      end
      val
    end
    
    def is_link?
      true
    end
  end
  
end

class Object
  def is_link?
    false
  end
end

def Object.linkable_attr(attr)
  attr_writer attr
  define_method(attr) do
    val = instance_variable_get("@#{attr}".to_sym)
    return val.real_value if val.respond_to? :real_value
    val
  end
end
