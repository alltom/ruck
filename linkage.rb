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
