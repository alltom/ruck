
def Object.linkable_attr(attr)
  attr_accessor attr
  define_method("link_#{attr}") do |proc|
    self.metaclass.send(:define_method, attr, &proc)
    self.metaclass.send(:define_method, "#{attr}_linked?".to_sym) { true }
  end
  define_method("unlink_#{attr}") do
    self.metaclass.send(:define_method, attr) { instance_variable_get("@#{attr}".to_sym) }
    self.metaclass.send(:define_method, "#{attr}_linked?".to_sym) { false }
  end
end

class Object
  def L(&block)
    block
  end
end
