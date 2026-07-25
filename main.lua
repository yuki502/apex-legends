local Game = require("src.game")
local Screen = require("src.graphics.screen")

local game

function love.load()
  love.graphics.setBackgroundColor(0, 0, 0)
  love.keyboard.setKeyRepeat(false)
  Screen.init()
  game = Game()
end

function love.update(dt)
  if dt > 0.1 then dt = 0.1 end
  game:update(dt)
end

function love.draw()
  Screen.drawLetterbox()
  Screen.apply()
  game:draw()
  Screen.clear()
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

local function toVirtual(x, y)
  return Screen.toVirtual(x, y)
end

function love.wheelmoved(x, y)
  if game and game.hangar then
    game.hangar:mousewheel(y)
  end
end

function love.mousemoved(x, y, dx, dy)
  if game and game.hangar then
    local vx, vy = toVirtual(x, y)
    local vdx, vdy = dx * Screen.getScale(), dy * Screen.getScale()
    game.hangar:mousemoved(vx, vy, vdx, vdy)
  end
end

function love.touchpressed(id, x, y)
  local vx, vy = toVirtual(x, y)
  game:touchpressed(id, vx, vy)
end

function love.touchmoved(id, x, y)
  local vx, vy = toVirtual(x, y)
  game:touchmoved(id, vx, vy)
end

function love.touchreleased(id)
  game:touchreleased(id)
end

function love.mousepressed(x, y, button)
  if button == 1 then
    local vx, vy = toVirtual(x, y)
    if game.state == "hangar" then
      game.hangar:mousepressed(vx, vy, button)
      return
    end
    game:touchpressed(0, vx, vy)
  end
end

function love.mousereleased(x, y, button)
  if button == 1 then
    game:touchreleased(0)
  end
end

function love.resize(w, h)
  Screen.update()
  if game and game.shader then
    game.shader:resize()
  end
end