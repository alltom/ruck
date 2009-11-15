
clear

loop do
  wait 2
  
  glTranslate(0, 0, -5)
  glutSolidCube(2)
  
  wait 0.1
  
  clear
end
