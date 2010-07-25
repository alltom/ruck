
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

shred1.go
shred2.go
shred1.go
shred2.go
shred1.go
shred2.go
