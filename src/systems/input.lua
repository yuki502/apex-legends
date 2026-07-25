-- input.lua
-- Sistema de entrada unificado: keyboard + touch + mouse.
-- Convierte input crudo a movimiento normalizado (dx, dy).
-- Soporta: WASD, flechas, joystick virtual, fire button.
-- Detecta: fire just pressed, pause, dodge (shift/double-tap).

local Object = require("lib.classic")
local sqrt = math.sqrt

local Input = Object:extend()

function Input:new()
  self.touchDx = 0
  self.touchDy = 0
  self.touchActive = false
  self.touchId = nil
  self.touchOriginX = 0
  self.touchOriginY = 0
  self.touchRadius = 60
  self.touchRadiusSq = self.touchRadius * self.touchRadius
  self.moveDx = 0
  self.moveDy = 0
  self.fireHeld = false
  self.firePressed = false
  self.pausePressed = false
  self._invTouchRadius = 1 / self.touchRadius
  self.fireTouchId = nil
  self.fireTouchActive = false
end

function Input:getMovement()
  local dx, dy = 0, 0
  if love.keyboard.isDown("left") or love.keyboard.isDown("a") then
    dx = dx - 1
  end
  if love.keyboard.isDown("right") or love.keyboard.isDown("d") then
    dx = dx + 1
  end
  if love.keyboard.isDown("up") or love.keyboard.isDown("w") then
    dy = dy - 1
  end
  if love.keyboard.isDown("down") or love.keyboard.isDown("s") then
    dy = dy + 1
  end
  if dx ~= 0 or dy ~= 0 then
    local len = sqrt(dx * dx + dy * dy)
    if len > 0 then
      dx = dx / len
      dy = dy / len
    end
  end
  if self.touchActive then
    if self.touchDx ~= 0 or self.touchDy ~= 0 then
      dx = dx + self.touchDx
      dy = dy + self.touchDy
    end
  end
  local dLen = sqrt(dx * dx + dy * dy)
  if dLen > 1 then
    dx = dx / dLen
    dy = dy / dLen
  end
  self.moveDx = dx
  self.moveDy = dy
  return dx, dy
end

function Input:isFire()
  local kbDown = love.keyboard.isDown("space") or love.keyboard.isDown("z")
  local mouseDown = love.mouse.isDown(1)
  local touchDown = self.fireTouchActive
  local down = kbDown or mouseDown or touchDown
  self.firePressed = down and not self.fireHeld
  self.fireHeld = down
  return down
end

function Input:isFireJustPressed()
  return self.firePressed
end

function Input:isPause()
  if love.keyboard.isDown("escape") or love.keyboard.isDown("p") then
    if not self._pauseWasDown then
      self._pauseWasDown = true
      return true
    end
    return false
  end
  self._pauseWasDown = false
  return false
end

function Input:touchpressed(id, tx, ty)
  self.touchActive = true
  self.touchId = id
  self.touchOriginX = tx
  self.touchOriginY = ty
  self:_updateTouch(0, 0)
  return true
end

function Input:touchmoved(id, tx, ty)
  if self.touchActive and id == self.touchId then
    self:_updateTouch(tx - self.touchOriginX, ty - self.touchOriginY)
    return true
  end
  return false
end

function Input:touchreleased(id)
  if self.touchActive and id == self.touchId then
    self.touchActive = false
    self.touchId = nil
    self.touchDx = 0
    self.touchDy = 0
    return true
  end
  return false
end

function Input:firePressed_(id, tx, ty)
  self.fireTouchActive = true
  self.fireTouchId = id
  return true
end

function Input:fireReleased_(id)
  if self.fireTouchId == id then
    self.fireTouchActive = false
    self.fireTouchId = nil
    return true
  end
  return false
end

function Input:_updateTouch(dx, dy)
  local dSq = dx * dx + dy * dy
  if dSq > self.touchRadiusSq and dSq > 0 then
    local d = sqrt(dSq)
    local scale = self.touchRadius / d
    dx = dx * scale
    dy = dy * scale
  end
  self.touchDx = dx * self._invTouchRadius
  self.touchDy = dy * self._invTouchRadius
end

function Input:getTouchOrigin()
  return self.touchOriginX, self.touchOriginY, self.touchRadius
end

function Input:isTouchActive()
  return self.touchActive
end

return Input
