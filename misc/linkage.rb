
def Object.linkable_attr(attr)
  define_method(attr) do
    instance_variable_get("@#{attr}")
  end
  define_method("#{attr}=") do |val|
    instance_variable_set("@#{attr}", val)
    if val.respond_to? :call
      meta_def attr do
        val.call
      end
    else
      meta_def attr do
        val
      end
    end
  end
end

class Object
  def L(&block)
    block
  end
end
