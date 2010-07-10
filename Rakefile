require 'rubygems'
require 'rake'

begin
  require "jeweler"
  Jeweler::Tasks.new do |gem|
    gem.name = "ruck"
    gem.email = "tom@alltom.com"
    gem.homepage = "http://github.com/alltom/ruck"
    gem.authors = ["Tom Lieber"]
    gem.summary = "strong timing for Ruby: cooperative threads on a virtual clock"
    gem.description = <<-EOF
      Ruck uses continuations and a simple scheduler to ensure "shreds"
      (Ruck threads) are woken at precisely the right time according
      to its virtual clock. Schedulers can map virtual time to samples
      in a WAV file, real time, time in a MIDI file, or anything else
      by overriding "sim_to" in the Shreduler class.
    EOF
    gem.has_rdoc = false
    # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end
