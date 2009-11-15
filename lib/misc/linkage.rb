
class Object
  def linkable_attr(attr_sym)
    attr_reader attr_sym
    define_method("#{attr_sym}=") do |val|
      instance_variable_set("@#{attr_sym}", val)
      if val.respond_to? :call
        meta_def attr_sym do
          val.call
        end
      else
        meta_def attr_sym do
          val
        end
      end
    end
  end

  def L(&block)
    block
  end
end
