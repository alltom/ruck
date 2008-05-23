
def Object.linkable_attr(attr)
  attr_accessor attr
  define_method("link_#{attr}") do |proc|
    self.metaclass.send(:define_method, attr, &proc)
  end
  define_method("unlink_#{attr}") do
    self.metaclass.send(:define_method, attr) { instance_variable_get("@#{attr}".to_sym) }
  end
end
