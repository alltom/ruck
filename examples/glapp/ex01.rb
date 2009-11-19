
clear

spork("framerate watcher") do
  start_time = Time.now
  frames = 0
  
  loop do
    wait_for_frame
    frames += 1
    if frames % 100 == 0
      puts "#{frames.to_f / (Time.now - start_time)}"
    end
  end
  
end

loop do
  wait 2
  
  glColor 1, 0, 0
  glTranslate(0, 0, -5)
  glutSolidCube(2)
  
  wait 0.1
  
  clear
end
