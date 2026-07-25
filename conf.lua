function love.conf(t)
  t.window.title = "Apex Legends - Space Shooter"
  t.window.width = 1400
  t.window.height = 800
  t.window.resizable = true
  t.window.vsync = 1
  t.window.msaa = 0
  t.window.orientation = "landscape"
  t.console = false
  t.identity = "apex-legends"
  t.modules.joystick = false
  t.modules.physics = false
  t.modules.thread = true
  t.externalstorage = true
  
  -- Android configuration
  if love.system.getOS() == "Android" then
    t.window.width = 1920
    t.window.height = 1080
    t.window.resizable = false
    t.android = {
      orientation = "landscape",
      useLowMemory = true,
      immersive = false
    }
  end
end
