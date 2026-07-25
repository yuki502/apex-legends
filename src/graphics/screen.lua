local Screen = {}

local DESIGN_W = 700
local DESIGN_H = 400
local DESIGN_ASPECT = DESIGN_W / DESIGN_H

local scale = 1
local invScale = 1
local offsetX = 0
local offsetY = 0
local screenW = DESIGN_W
local screenH = DESIGN_H
local fullscreenW = DESIGN_W
local fullscreenH = DESIGN_H

function Screen.init()
  Screen.update()
end

function Screen.update()
  fullscreenW = love.graphics.getWidth()
  fullscreenH = love.graphics.getHeight()
  local windowAspect = fullscreenW / fullscreenH
  if windowAspect > DESIGN_ASPECT then
    scale = fullscreenH / DESIGN_H
    offsetX = math.floor((fullscreenW - DESIGN_W * scale) / 2)
    offsetY = 0
  else
    scale = fullscreenW / DESIGN_W
    offsetX = 0
    offsetY = math.floor((fullscreenH - DESIGN_H * scale) / 2)
  end
  invScale = 1 / scale
  screenW = DESIGN_W
  screenH = DESIGN_H
end

function Screen.getWidth()
  return screenW
end

function Screen.getHeight()
  return screenH
end

function Screen.getDesignWidth()
  return DESIGN_W
end

function Screen.getDesignHeight()
  return DESIGN_H
end

function Screen.getScale()
  return scale
end

function Screen.getOffsets()
  return offsetX, offsetY
end

function Screen.toVirtual(sx, sy)
  return (sx - offsetX) * invScale, (sy - offsetY) * invScale
end

function Screen.toScreen(vx, vy)
  return vx * scale + offsetX, vy * scale + offsetY
end

function Screen.apply()
  love.graphics.push()
  love.graphics.translate(offsetX, offsetY)
  love.graphics.scale(scale)
end

function Screen.clear()
  love.graphics.pop()
end

function Screen.fontSize(base)
  return math.max(6, math.floor(base * scale * 0.5 + base * 0.5))
end

function Screen.drawLetterbox()
  local r, g, b, a = love.graphics.getBackgroundColor()
  love.graphics.setColor(r, g, b, a or 1)
  if offsetX > 0 then
    love.graphics.rectangle("fill", 0, 0, offsetX, fullscreenH)
    love.graphics.rectangle("fill", fullscreenW - offsetX, 0, offsetX, fullscreenH)
  end
  if offsetY > 0 then
    love.graphics.rectangle("fill", 0, 0, fullscreenW, offsetY)
    love.graphics.rectangle("fill", 0, fullscreenH - offsetY, fullscreenW, offsetY)
  end
  love.graphics.setColor(1, 1, 1, 1)
end

return Screen
