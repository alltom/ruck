
spork do
  loop do
    ev = wait_for_key_down
    puts "you pressed #{ev.key}"
  end
end

clear
