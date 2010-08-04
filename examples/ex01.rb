
require "ruck"

include Ruck

shred1 = Shred.new do |shred|
  puts "A"
  Shred.current.pause
  puts "B"
  Shred.current.pause
  puts "C"
end

shred2 = Shred.new do |shred|
  puts "1"
  Shred.current.pause
  puts "2"
  Shred.current.pause
  puts "3"
end

shred1.call
shred2.call
shred1.call
shred2.call
shred1.call
shred2.call
