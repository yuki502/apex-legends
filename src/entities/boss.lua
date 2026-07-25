local Object = require("lib.classic")
local lume = require("lib.lume")
local Screen = require("src.graphics.screen")

local sin = math.sin
local cos = math.cos
local pi = math.pi
local min = math.min
local max = math.max
local lg = love.graphics
local lw = Screen.getWidth

local Boss = Object:extend()

local _bossVerts = {}
local _bossBulletPool = {
  {x=0,y=0,vx=0,vy=0}, {x=0,y=0,vx=0,vy=0}, {x=0,y=0,vx=0,vy=0},
  {x=0,y=0,vx=0,vy=0}, {x=0,y=0,vx=0,vy=0},
  {x=0,y=0,vx=0,vy=0}, {x=0,y=0,vx=0,vy=0}, {x=0,y=0,vx=0,vy=0},
}
local _bossBulletCount = 0

function Boss:new(wave, template)
  local w = lw()
  local tmpl = template or {}
  self.x = w / 2
  self.y = -60
  self.targetY = 80
  self.radius = tmpl.radiusBase or (38 + min(wave, 10) * 2)
  self.hp = tmpl.hpBase or (25 + wave * 4)
  self.maxHp = self.hp
  self.speed = tmpl.speedBase or (35 + wave * 2)
  self.alive = true
  self.t = 0
  self.shootTimer = 0
  self.shootRate = tmpl.shootRateBase or max(0.35, 1.1 - wave * 0.03)
  self.color = tmpl.color or {0.85, 0.1, 0.15}
  self.accent = tmpl.accent or {1, 0.3, 0.2}
  self.moveDir = 1
  self.entering = true
  self.wave = wave
  self.scoreValue = tmpl.scoreBase or (100 + wave * 20)
  self.name = tmpl.name or "BOSS"
  self.coins = tmpl.coinsBase or (15 + wave * 3)
  self.isSuperBoss = false
  self.superPhase = 0
  self.defeated = false
end

function Boss:update(dt)
  self.t = self.t + dt

  if self.entering then
    self.y = self.y + 80 * dt
    if self.y >= self.targetY then
      self.y = self.targetY
      self.entering = false
    end
    return
  end

  self.x = self.x + self.speed * self.moveDir * dt
  local w = lw()
  if self.x > w - self.radius - 20 then
    self.moveDir = -1
  elseif self.x < self.radius + 20 then
    self.moveDir = 1
  end

  self.shootTimer = self.shootTimer - dt
end

function Boss:canShoot()
  if self.entering then return false end
  if self.shootTimer <= 0 then
    self.shootTimer = self.shootRate
    return true
  end
  return false
end

function Boss:getBullets()
  _bossBulletCount = 0
  local spread = 0.3
  local count = min(3 + math.floor(self.wave / 15), 7)
  for i = -(count - 1) / 2, (count - 1) / 2 do
    _bossBulletCount = _bossBulletCount + 1
    local b = _bossBulletPool[_bossBulletCount]
    b.x = self.x
    b.y = self.y + self.radius
    b.vx = sin(i * spread) * 150
    b.vy = 180
  end
  if self.wave >= 15 then
    for side = -1, 1, 2 do
      _bossBulletCount = _bossBulletCount + 1
      local b = _bossBulletPool[_bossBulletCount]
      b.x = self.x + side * (self.radius * 0.6)
      b.y = self.y + self.radius * 0.8
      b.vx = side * 80
      b.vy = 200
    end
  end
  return _bossBulletPool, _bossBulletCount
end

function Boss:hit(damage)
  self.hp = self.hp - damage
  if self.hp <= 0 then
    self.alive = false
    self.defeated = true
    return true
  end
  return false
end

function Boss:draw()
  local r, g, b = self.color[1], self.color[2], self.color[3]
  local ar, ag, ab = self.accent[1], self.accent[2], self.accent[3]
  local pulse = sin(self.t * 3) * 0.1 + 0.9
  local px, py = self.x, self.y

  lg.setColor(r, g, b, 0.1)
  lg.circle("fill", px, py, self.radius + 18)
  lg.setColor(r, g, b, 0.2)
  lg.circle("fill", px, py, self.radius + 8)
  lg.setColor(r, g, b, 0.3)
  lg.circle("fill", px, py, self.radius + 3)

  local sides = 8
  local vertCount = 0
  for i = 0, sides - 1 do
    local angle = (i / sides) * pi * 2 - pi / 2
    local outerR = self.radius
    local innerR = self.radius * 0.65
    vertCount = vertCount + 1
    _bossVerts[vertCount * 2 - 1] = px + cos(angle) * outerR
    _bossVerts[vertCount * 2] = py + sin(angle) * outerR
    local midAngle = angle + pi / sides
    vertCount = vertCount + 1
    _bossVerts[vertCount * 2 - 1] = px + cos(midAngle) * innerR
    _bossVerts[vertCount * 2] = py + sin(midAngle) * innerR
  end

  lg.setColor(r * 0.5, g * 0.5, b * 0.5, 0.7)
  lg.polygon("fill", _bossVerts)
  lg.setColor(ar, ag, ab, pulse * 0.3)
  lg.setLineWidth(5)
  lg.polygon("line", _bossVerts)
  lg.setColor(ar, ag, ab, pulse)
  lg.setLineWidth(2)
  lg.polygon("line", _bossVerts)

  lg.setColor(ar, ag, ab, 0.5)
  lg.circle("fill", px, py, self.radius * 0.3)
  lg.setColor(1, 0.2, 0.1, 0.8)
  lg.circle("fill", px, py, self.radius * 0.15)

  local hpRatio = self.hp / self.maxHp
  local barW = self.radius * 2
  local barH = 6
  local barX = px - barW / 2
  local barY = py - self.radius - 16

  lg.setColor(0, 0, 0, 0.5)
  lg.rectangle("fill", barX - 1, barY - 1, barW + 2, barH + 2, 3, 3)
  lg.setColor(0.2, 0.2, 0.2, 0.8)
  lg.rectangle("fill", barX, barY, barW, barH, 2, 2)

  local hpR, hpG, hpB
  if hpRatio > 0.5 then
    hpR, hpG, hpB = 0.2, 0.9, 0.3
  elseif hpRatio > 0.25 then
    hpR, hpG, hpB = 1, 0.7, 0.2
  else
    hpR, hpG, hpB = 1, 0.2, 0.2
  end
  lg.setColor(hpR, hpG, hpB, 0.9)
  lg.rectangle("fill", barX, barY, barW * hpRatio, barH, 2, 2)

  lg.setColor(1, 1, 1, 1)
end

return Boss
