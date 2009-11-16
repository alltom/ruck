
begin
  require "jeweler"
  Jeweler::Tasks.new do |gemspec|
    gemspec.name = "ruck"
    gemspec.email = "tom@alltom.com"
    gemspec.homepage = "http://github.com/alltom/ruck"
    gemspec.authors = ["Tom Lieber"]
    gemspec.summary = "strong timing for Ruby: cooperative threads on a virtual clock"
    gemspec.description = <<-EOF
      Ruck uses continuations and a simple scheduler to ensure "shreds"
      (threads in Ruck) are woken at precisely the right time according
      to its virtual clock. Schedulers can map virtual time to samples
      in a WAV file, real time, time in a MIDI file, or anything else
      by overriding "sim_to" in the Shreduler class.
      
      A small library of useful unit generators and plenty of examples
      are provided. See the README or the web page for details.
    EOF
    gemspec.has_rdoc = false
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jewler not available. Install it with: sudo gem install jeweler"
end
