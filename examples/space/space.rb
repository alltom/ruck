## Notes from the original file:
##  Author: Dirk Johnson
##  Version: 1.0.0
##  Date: 2007-10-05
##  License: Same as for Gosu (MIT)
##  Comments: Based on the Gosu Ruby Tutorial, but incorporating the Chipmunk Physics Engine
##  See http://code.google.com/p/gosu/wiki/RubyChipmunkIntegration for the accompanying text.
##  originally http://gosu.googlecode.com/svn/trunk/examples/ChipmunkIntegration.rb

## ruck adaptation by Tom Lieber, 2010-08-01
## 
## all of these are now handled by shreds in a GameShreduler:
## - physics updates
## - star animation
## - adding stars
## - drawing
## - framerate calculation

require "rubygems"
require "gosu"
require "chipmunk"
require "ruck"

include Ruck

SCREEN_WIDTH = 640
SCREEN_HEIGHT = 480

# Amount of time in seconds between physics steps.
# (6 times per frame at 60fps)
PHYSICS_STEP_SIZE = (1.0 / 60.0) / 6.0

# a real-time shreduler that expects you to wake it up every now
# and then with GameShreduler#catch_up, when it'll run all the
# shreds that were scheduled for the time period between the last
# call and now. it's not very accurate unless you're calling it often.
class GameShreduler < Ruck::Shreduler
  def start_time
    @start_time ||= Time.now
  end
  
  def actual_now
    Time.now - start_time
  end
  
  def catch_up
    run_until actual_now
  end
end

class Numeric
  # convenience method for converting from radians to a unit Vec2
  def radians_to_vec2
    CP::Vec2.new(Math::cos(self), Math::sin(self))
  end
end

module ZOrder
  # sprite layers
  Background, Stars, Player, UI = *0..3
end

class Ship
  attr_reader :shape

  def initialize(window, shape)
    @image = Gosu::Image.new(window, "media/Starfighter.bmp", false)
    @shape = shape
    @shape.body.p = CP::Vec2.new(0.0, 0.0) # position
    @shape.body.v = CP::Vec2.new(0.0, 0.0) # velocity
    
    # Keep in mind that down the screen is positive y, which means that PI/2 radians,
    # which you might consider the top in the traditional Trig unit circle sense is actually
    # the bottom; thus 3PI/2 is the top
    @shape.body.a = (3*Math::PI/2.0) # angle in radians; faces towards top of screen
  end
  
  # Directly set the position of our ship
  def warp(vect)
    @shape.body.p = vect
  end
  
  # Apply negative torque
  def turn_left
    @shape.body.t -= 900.0
  end
  
  # Apply positive torque
  def turn_right
    @shape.body.t += 900.0
  end
  
  # Apply forward force
  def accelerate
    @shape.body.apply_force((@shape.body.a.radians_to_vec2 * 3000.0), CP::Vec2.new(0.0, 0.0))
  end
  
  # Apply even more forward force
  def boost
    @shape.body.apply_force((@shape.body.a.radians_to_vec2 * 6000.0), CP::Vec2.new(0.0, 0.0))
  end
  
  # Apply reverse force
  def reverse
    @shape.body.apply_force(-(@shape.body.a.radians_to_vec2 * 3000.0), CP::Vec2.new(0.0, 0.0))
  end
  
  # Wrap to the other side of the screen when we fly off the edge
  def validate_position
    @shape.body.p = CP::Vec2.new(@shape.body.p.x % SCREEN_WIDTH, @shape.body.p.y % SCREEN_HEIGHT)
  end
  
  def draw
    @image.draw_rot(@shape.body.p.x, @shape.body.p.y, ZOrder::Player, @shape.body.a.radians_to_gosu)
  end
end

# animated star sprite
class Star
  attr_reader :shape
  
  def initialize(animation, shape)
    @animation = animation
    @color = Gosu::Color.new(0xff000000)
    @color.red = rand(255 - 40) + 40
    @color.green = rand(255 - 40) + 40
    @color.blue = rand(255 - 40) + 40
    @shape = shape
    @shape.body.p = CP::Vec2.new(rand * SCREEN_WIDTH, rand * SCREEN_HEIGHT) # position
    @shape.body.v = CP::Vec2.new(0.0, 0.0) # velocity
    @shape.body.a = (3*Math::PI/2.0) # angle in radians; faces towards top of screen
    
    @frame = 0
    @anim_shred = spork_loop do
      @frame = (@frame + 1) % @animation.size
      Shred.yield(0.1)
    end
  end

  def draw
    img = @animation[@frame]
    img.draw(@shape.body.p.x - img.width / 2.0,
             @shape.body.p.y - img.height / 2.0,
             ZOrder::Stars, 1, 1, @color, :additive)
  end
  
  def kill
    @anim_shred.kill
  end
end

class GameWindow < Gosu::Window
  def initialize
    super(SCREEN_WIDTH, SCREEN_HEIGHT, false, 16)
    self.caption = "Gosu & Chipmunk & ruck Integration Demo"
    
    @score = 0
    @stars = Array.new
    @dead_star_shapes = []
    
    ruck_start
    
    load_resources
    
    setup_physics
  end
  
  def ruck_start
    @shreduler = GameShreduler.new
    @shreduler.make_convenient
    
    spork_loop(PHYSICS_STEP_SIZE) do
      physics_update
    end
    
    spork_loop do
      if @stars.length < 25
        body = CP::Body.new(0.0001, 0.0001)
        shape = CP::Shape::Circle.new(body, 25/2, CP::Vec2.new(0.0, 0.0))
        shape.collision_type = :star

        @space.add_body(body)
        @space.add_shape(shape)

        @stars.push(Star.new(@star_animation_frames, shape))
      end
      
      Shred.yield(rand * 1)
    end
    
    spork_loop do
      Shred.wait_on(:frame)
      
      @background_image.draw(0, 0, ZOrder::Background)
      @ship.draw
      @stars.each { |star| star.draw }
      @font.draw("Score: #{@score}", 10, 10, ZOrder::UI, 1.0, 1.0, 0xffffff00)
      @font.draw("Framerate: #{@framerate}", 10, 33, ZOrder::UI, 1.0, 1.0, 0xffffff00)
    end
    
    @framerate = 0.0
    @frames = 0
    spork_loop do
      Shred.wait_on(:frame)
      @frames += 1
      @framerate = @frames / @shreduler.actual_now
    end
  end
  
  def load_resources
    @background_image = Gosu::Image.new(self, "media/Space.png", true)
    @beep = Gosu::Sample.new(self, "media/Beep.wav")
    @font = Gosu::Font.new(self, Gosu::default_font_name, 20)
    @star_animation_frames = Gosu::Image::load_tiles(self, "media/Star.png", 25, 25, false)
  end
  
  def setup_physics
    @space = CP::Space.new
    @space.damping = 0.2
    
    # create the body and shape for the ship
    body = CP::Body.new(10.0, 150.0) # mass, inertia
    shape_array = [CP::Vec2.new(-25.0, -25.0), # the "top" is towards 0 radians (the right)
                   CP::Vec2.new(-25.0, 25.0),
                   CP::Vec2.new(25.0, 1.0),
                   CP::Vec2.new(25.0, -1.0)]
    shape = CP::Shape::Poly.new(body, shape_array, CP::Vec2.new(0,0))
    shape.collision_type = :ship
    @space.add_body(body)
    @space.add_shape(shape)
    
    @ship = Ship.new(self, shape)
    @ship.warp(CP::Vec2.new(SCREEN_WIDTH/2, SCREEN_HEIGHT/2))
    
    # we cannot remove shapes or bodies from space within a collision closure,
    # so we save them in @dead_star_shapes to be removed in physics_update
    @space.add_collision_func(:ship, :star) do |ship_shape, star_shape|
      @score += 10
      @beep.play
      @dead_star_shapes << star_shape
    end
    
    # prevent stars from bumping into one another
    @space.add_collision_func(:star, :star, &nil)
  end

  def draw
    @shreduler.catch_up
    @shreduler.raise_all :frame
    @shreduler.catch_up
  end
  
  def physics_update
    @dead_star_shapes.each do |shape|
      @stars.delete_if do |star|
        if star.shape == shape
          star.kill
          true
        end
      end
      @space.remove_body(shape.body)
      @space.remove_shape(shape)
    end
    @dead_star_shapes.clear
    
    # forces are cumulative, so reset them for this update
    @ship.shape.body.reset_forces
    
    # Wrap around the screen to the other side
    @ship.validate_position
    
    # apply forces to ship based on keyboard state
    if button_down? Gosu::KbLeft
      @ship.turn_left
    end
    if button_down? Gosu::KbRight
      @ship.turn_right
    end
    
    if button_down? Gosu::KbUp
      if ( (button_down? Gosu::KbRightShift) || (button_down? Gosu::KbLeftShift) )
        @ship.boost
      else
        @ship.accelerate
      end
    elsif button_down? Gosu::KbDown
      @ship.reverse
    end
    
    @space.step(PHYSICS_STEP_SIZE)
  end

  def button_down(id)
    if id == Gosu::KbEscape
      close
    end
  end
end

window = GameWindow.new
window.show
