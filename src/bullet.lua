local Object = require("lib.classic")

local sqrt = math.sqrt
local cos = math.cos
local sin = math.sin
local lg = love.graphics
local lw = lg.getWidth
local lh = lg.getHeight

local Bullet = Object:extend()

function Bullet:new(x, y, isEnemy)
  self.x = x
  self.y = y
  self.isEnemy = isEnemy or false
  self.speed = isEnemy and 250 or 500
  self.radius = isEnemy and 6 or 5
  self.length = isEnemy and 10 or 14
  self.vx = 0
  self.vy = 0
  self.damage = 1
  self.homing = 0
  self.ricochet = 0
  self.critChance = 0
  self.lifesteal = 0
  self.bounces = 0
  self.alive = true
  self.ttl = 3
end

function Bullet:directed(x, y, vx, vy)
  self.x = x
  self.y = y
  self.isEnemy = true
  self.speed = sqrt(vx * vx + vy * vy)
  self.vx = vx
  self.vy = vy
  self.radius = 6
  self.length = 10
  return self
end

function Bullet:update(dt, enemies)
  self.ttl = self.ttl - dt
  if self.ttl <= 0 then
    self.alive = false
    return false
  end

  if self.homing and self.homing > 0 and not self.isEnemy and enemies and #enemies > 0 then
    local closest, closestDist = nil, 999999
    for i = 1, #enemies do
      local e = enemies[i]
      if e and e.alive then
        local dx = e.x - self.x
        local dy = e.y - self.y
        local d = dx * dx + dy * dy
        if d < closestDist then
          closestDist = d
          closest = e
        end
      end
    end
    if closest then
      local dx = closest.x - self.x
      local dy = closest.y - self.y
      local len = sqrt(dx * dx + dy * dy)
      if len > 0 then
        local homingStr = self.homing * 3
        self.vx = self.vx + (dx / len) * homingStr * dt
        self.vy = self.vy + (dy / len) * homingStr * dt
        local spd = sqrt(self.vx * self.vx + self.vy * self.vy)
        if spd > self.speed then
          self.vx = (self.vx / spd) * self.speed
          self.vy = (self.vy / spd) * self.speed
        end
      end
    end
  end

  if self.vx ~= 0 or self.vy ~= 0 then
    self.x = self.x + self.vx * dt
    self.y = self.y + self.vy * dt
  else
    self.y = self.y - self.speed * dt
  end
  local w = lw()
  local h = lh()

  -- ricochet off walls
  if self.ricochet > 0 and self.bounces < self.ricochet then
    local bounced = false
    if self.x < 0 then self.x = 0; self.vx = -self.vx; bounced = true end
    if self.x > w then self.x = w; self.vx = -self.vx; bounced = true end
    if self.y < 0 then self.y = 0; self.vy = -self.vy; bounced = true end
    if bounced then self.bounces = self.bounces + 1 end
  end

  if self.isEnemy then
    if self.y > h + 20 or self.x < -20 or self.x > w + 20 then
      self.alive = false
      return false
    end
    return true
  end
  if self.y > -self.length then return true end
  self.alive = false
  return false
end

function Bullet:isCrit()
  return self.critChance > 0 and love.math.random() < self.critChance
end

function Bullet:getDamage()
  if self:isCrit() then
    return self.damage * 2
  end
  return self.damage
end

function Bullet:draw()
  local px, py = self.x, self.y
  local r, g, b
  if self.isEnemy then
    r, g, b = 1, 0.3, 0.2
  else
    r, g, b = 0.3, 1, 0.5
  end

  -- crit glow
  if self.critChance > 0 then
    lg.setColor(1, 0.8, 0.2, 0.1)
    lg.circle("fill", px, py, self.radius * 3)
  end

  lg.setColor(r, g, b, 0.15)
  lg.circle("fill", px, py + self.length * 0.15, self.radius * 2)
  lg.setColor(r, g, b, 0.5)
  lg.ellipse("fill", px, py, self.radius * 0.8, self.length * 0.5)
  if not self.isEnemy then
    lg.setColor(0.8, 1, 0.9, 1)
  else
    lg.setColor(1, 0.5, 0.4, 1)
  end
  lg.ellipse("fill", px, py - self.length * 0.15, self.radius * 0.4, self.length * 0.4)
  lg.setColor(1, 1, 1, 1)
  lg.circle("fill", px, py - self.length * 0.3, 2.5)
end

return Bullet
