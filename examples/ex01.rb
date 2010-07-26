
require "ruck"

include Ruck

shred1 = Shred.new do |shred|
  puts "A"
  shred.pause
  puts "B"
  shred.pause
  puts "C"
end

shred2 = Shred.new do |shred|
  puts "1"
  shred.pause
  puts "2"
  shred.pause
  puts "3"
end

shred1.call
shred2.call
shred1.call
shred2.call
shred1.call
shred2.call
