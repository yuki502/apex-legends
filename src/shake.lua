local Object = require("lib.classic")
local lume = require("lib.lume")

local Shake = Object:extend()

function Shake:new()
  self.intensity = 0
  self.duration = 0
  self.timer = 0
  self.offsetX = 0
  self.offsetY = 0
end

function Shake:trigger(intensity, duration)
  self.intensity = math.max(self.intensity, intensity)
  self.duration = math.max(self.duration, duration)
  self.timer = self.duration
end

function Shake:update(dt)
  if self.timer > 0 then
    self.timer = self.timer - dt
    local ratio = self.timer / self.duration
    local currentIntensity = self.intensity * ratio
    self.offsetX = lume.random(-1, 1) * currentIntensity
    self.offsetY = lume.random(-1, 1) * currentIntensity
    if self.timer <= 0 then
      self.offsetX = 0
      self.offsetY = 0
      self.intensity = 0
      self.duration = 0
    end
  end
end

function Shake:getOffset()
  return self.offsetX, self.offsetY
end

return Shake
