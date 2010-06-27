
# linkable_attr generates accessor methods for
# instance variables that behaves almost like
# attr_accessor.

# The difference is that if an object is assigned
# which responds to :call, accessing the method
# returns the result of invoking :call instead of
# the Proc/lambda/block itself.

# relies on _why's metaid, included below.

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

# stolen from metaid.rb:
# http://whytheluckystiff.net/articles/seeingMetaclassesClearly.html
# (that site does not exist, but a mirror can be found)
class Object
  # The hidden singleton lurks behind everyone
  def metaclass; class << self; self; end; end
  def meta_eval &blk; metaclass.instance_eval &blk; end

  # Adds methods to a metaclass
  def meta_def name, &blk
    meta_eval { define_method name, &blk }
  end

  # Defines an instance method within a class
  def class_def name, &blk
    class_eval { define_method name, &blk }
  end
end
