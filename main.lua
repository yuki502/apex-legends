-- APEX LEGENDS - Space Shooter
-- Entry point: LOVE2D callbacks bridge to the Game class
-- All game logic lives in src/game.lua

local Game = require("src.game")

local game

function love.load()
  love.graphics.setBackgroundColor(0, 0, 0)
  love.keyboard.setKeyRepeat(false)
  game = Game()
end

function love.update(dt)
  if dt > 0.1 then dt = 0.1 end
  game:update(dt)
end

function love.draw()
  game:draw()
end

function love.keypressed(key)
  if game.state == "hangar" then
    if game.hangar then
      game.hangar:keypressed(key)
    end
    return
  end
  if key == "escape" then
    love.event.quit()
  end
end

-- Hangar mouse events (component drag-and-drop UI)
function love.wheelmoved(x, y)
  if game and game.hangar then
    game.hangar:mousewheel(y)
  end
end

function love.mousemoved(x, y, dx, dy)
  if game and game.hangar then
    game.hangar:mousemoved(x, y, dx, dy)
  end
end

-- Touch input (also used for mouse via emulated touch)
function love.touchpressed(id, x, y)
  game:touchpressed(id, x, y)
end

function love.touchmoved(id, x, y)
  game:touchmoved(id, x, y)
end

function love.touchreleased(id)
  game:touchreleased(id)
end

function love.mousepressed(x, y, button)
  if button == 1 then
    if game.state == "hangar" then
      game.hangar:mousepressed(x, y, button)
      return
    end
    game:touchpressed(0, x, y)
  end
end

function love.mousereleased(x, y, button)
  if button == 1 then
    game:touchreleased(0)
  end
end

function love.resize(w, h)
end
