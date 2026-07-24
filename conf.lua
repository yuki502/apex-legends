function love.conf(t)
  t.window.title = "Apex Legends - Space Shooter"
  t.window.width = 700
  t.window.height = 400
  t.window.resizable = false
  t.window.vsync = 1
  t.window.msaa = 0
  t.window.orientation = "landscape"
  t.console = false
  t.identity = "apex-legends"
  t.modules.joystick = false
  t.modules.physics = false
end
