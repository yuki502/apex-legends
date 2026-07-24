local Object = require("lib.classic")
local lume = require("lib.lume")

local sin = math.sin
local cos = math.cos
local min = math.min
local floor = math.floor
local lg = love.graphics
local lw = lg.getWidth
local lh = lg.getHeight

local Enemy = Object:extend()

local _drawPts = {}

function Enemy:new(wave, typeDef)
  local t = typeDef
  if not t then
    local EnemyTypes = require("src.enemy_types")
    local available, totalWeight = EnemyTypes.getForWave(wave or 1)
    t = EnemyTypes.pick(available, totalWeight)
  end

  local hpMul, dmgMul, spdMul = 1, 1, 1
  if wave then
    hpMul, dmgMul, spdMul = (require("src.enemy_types")).getScaling(wave)
  end

  self.x = love.math.random(30, lw() - 30)
  self.y = -25
  self.speed = lume.random(t.speed[1], t.speed[2]) * spdMul
  self.radius = t.radius
  self.hp = floor(t.hp * hpMul)
  self.maxHp = self.hp
  self.color = {t.color[1], t.color[2], t.color[3]}
  self.verts = t.verts
  self.alive = true
  self.rot = 0
  self.rotSpeed = lume.random(-2, 2)
  self.points = t.points
  self.xp = t.xp or 5
  self.credits = t.credits or 2
  self.name = t.name
  self.wave = wave or 1
  self.t = 0
  self.sineAmp = lume.random(t.sineAmp[1], t.sineAmp[2])
  self.sineFreq = lume.random(t.sineFreq[1], t.sineFreq[2])
  self.startX = self.x

  self.behavior = t.behavior or "straight"
  self.shootChance = t.shootChance or 0
  self.shootTimer = 0
  self.shootPattern = t.shootPattern
  self.burstCount = t.burstCount or 0
  self.burstDelay = t.burstDelay or 0.15
  self.burstTimer = 0
  self.burstShots = 0
  self.bulletSpeed = t.bulletSpeed or 180
  self.bulletCount = t.bulletCount or 1
  self.aimAtPlayer = t.aimAtPlayer or false

  self.diveSpeed = t.diveSpeed or 0
  self.dashSpeed = t.dashSpeed or 0
  self.dashCooldown = t.dashCooldown and lume.random(t.dashCooldown[1], t.dashCooldown[2]) or 0
  self.dashTimer = self.dashCooldown
  self.dashing = false
  self.dashTime = 0

  self.shieldHp = t.shieldHp or 0
  self.shieldRadius = t.shieldRadius or 0

  self.frozen = 0
  self.knockbackX = 0
  self.knockbackY = 0
end

function Enemy:update(dt, playerX, playerY)
  if self.frozen > 0 then
    self.frozen = self.frozen - dt
    return
  end

  self.t = self.t + dt

  if self.knockbackX ~= 0 or self.knockbackY ~= 0 then
    self.x = self.x + self.knockbackX * dt * 5
    self.y = self.y + self.knockbackY * dt * 5
    self.knockbackX = self.knockbackX * 0.9
    self.knockbackY = self.knockbackY * 0.9
    if math.abs(self.knockbackX) < 0.1 then self.knockbackX = 0 end
    if math.abs(self.knockbackY) < 0.1 then self.knockbackY = 0 end
  end

  local spd = self.speed

  if self.behavior == "straight" then
    self.y = self.y + spd * dt
    if self.sineAmp > 0 then
      self.x = self.startX + sin(self.t * self.sineFreq) * self.sineAmp
    end

  elseif self.behavior == "dodge" then
    self.y = self.y + spd * dt
    if self.sineAmp > 0 then
      self.x = self.startX + sin(self.t * self.sineFreq) * self.sineAmp
    end
    if playerX and math.abs(self.x - playerX) < 40 and self.y < lh() * 0.6 then
      self.x = self.x + (self.x > playerX and 1 or -1) * spd * 1.2 * dt
    end

  elseif self.behavior == "strafe" then
    self.y = self.y + spd * 0.6 * dt
    self.x = self.x + sin(self.t * self.sineFreq) * self.sineAmp * dt * 3

  elseif self.behavior == "zonal" then
    local targetY = lh() * 0.25
    if self.y < targetY then
      self.y = self.y + spd * dt
    else
      self.x = self.x + sin(self.t * self.sineFreq) * self.sineAmp * dt * 2
    end
    self.shootTimer = self.shootTimer - dt

  elseif self.behavior == "sniper" then
    local targetY = lh() * 0.15
    if self.y < targetY then
      self.y = self.y + spd * dt
    else
      self.x = self.x + sin(self.t * 0.3) * 20 * dt
    end
    self.shootTimer = self.shootTimer - dt

  elseif self.behavior == "kamikaze" then
    if playerX and playerY then
      local dx = playerX - self.x
      local dy = playerY - self.y
      local dist = math.sqrt(dx * dx + dy * dy)
      if dist > 5 then
        self.x = self.x + (dx / dist) * self.diveSpeed * dt
        self.y = self.y + (dy / dist) * self.diveSpeed * dt
      end
    else
      self.y = self.y + spd * dt
    end

  elseif self.behavior == "tank" then
    self.y = self.y + spd * dt
    self.shootTimer = self.shootTimer - dt

  elseif self.behavior == "bomber" then
    self.y = self.y + spd * 0.5 * dt
    self.x = self.x + sin(self.t * self.sineFreq) * self.sineAmp * dt * 2
    self.shootTimer = self.shootTimer - dt

  elseif self.behavior == "dash" then
    self.dashTimer = self.dashTimer - dt
    if self.dashing then
      self.dashTime = self.dashTime - dt
      self.y = self.y + self.dashSpeed * dt
      if self.dashTime <= 0 then
        self.dashing = false
      end
    else
      self.y = self.y + spd * 0.4 * dt
      if self.sineAmp > 0 then
        self.x = self.startX + sin(self.t * self.sineFreq) * self.sineAmp
      end
      if self.dashTimer <= 0 and playerY and self.y < playerY - 50 then
        self.dashing = true
        self.dashTime = 0.3
        self.dashTimer = self.dashCooldown
      end
    end

  elseif self.behavior == "shield" then
    self.y = self.y + spd * dt
    if self.sineAmp > 0 then
      self.x = self.startX + sin(self.t * self.sineFreq) * self.sineAmp
    end
    self.shootTimer = self.shootTimer - dt
  end

  self.rot = self.rot + self.rotSpeed * dt

  if self.y > lh() + self.radius + 20 then
    self.alive = false
  end
  if self.x < -50 or self.x > lw() + 50 then
    self.alive = false
  end
end

function Enemy:canShoot()
  if self.shootChance <= 0 then return false end
  if self.y < 10 then return false end
  if self.shootTimer > 0 then return false end
  if math.random() < self.shootChance then
    self.shootTimer = 0.8 + math.random() * 1.5
    return true
  end
  return false
end

local _bulletPool = {}
local _bulletPoolCount = 0
local MAX_ENEMY_BULLETS = 256

for i = 1, MAX_ENEMY_BULLETS do
  _bulletPool[i] = { x = 0, y = 0, vx = 0, vy = 0 }
end
_bulletPoolCount = MAX_ENEMY_BULLETS

local _resultPool = {}
local _resultPoolCount = 0
local MAX_RESULTS = 32

for i = 1, MAX_RESULTS do
  _resultPool[i] = {}
end
_resultPoolCount = MAX_RESULTS

local function acquireResult()
  if _resultPoolCount > 0 then
    local r = _resultPool[_resultPoolCount]
    _resultPool[_resultPoolCount] = nil
    _resultPoolCount = _resultPoolCount - 1
    -- clear it
    for i = #r, 1, -1 do r[i] = nil end
    return r
  end
  return {}
end

local function acquireBullet()
  if _bulletPoolCount > 0 then
    local b = _bulletPool[_bulletPoolCount]
    _bulletPool[_bulletPoolCount] = nil
    _bulletPoolCount = _bulletPoolCount - 1
    return b
  end
  return { x = 0, y = 0, vx = 0, vy = 0 }
end

function Enemy:getBullets(playerX, playerY)
  local bx, by = self.x, self.y + self.radius
  local result = acquireResult()

  if self.shootPattern == "burst" then
    local count = math.min(self.burstCount, 8)
    for i = 1, count do
      local angle = (i - (count + 1) / 2) * 0.2
      local b = acquireBullet()
      b.x = bx; b.y = by
      b.vx = math.sin(angle) * self.bulletSpeed
      b.vy = self.bulletSpeed
      result[i] = b
    end
  elseif self.shootPattern == "spread" then
    local count = math.min(self.bulletCount, 8)
    for i = 1, count do
      local angle = (i - (count + 1) / 2) * 0.35
      local b = acquireBullet()
      b.x = bx; b.y = by
      b.vx = math.sin(angle) * self.bulletSpeed
      b.vy = self.bulletSpeed
      result[i] = b
    end
  elseif self.shootPattern == "rain" then
    local count = math.min(self.bulletCount, 12)
    for i = 1, count do
      local b = acquireBullet()
      b.x = bx + (i - (count + 1) / 2) * 12
      b.y = by
      b.vx = 0
      b.vy = self.bulletSpeed * 0.8
      result[i] = b
    end
  elseif self.aimAtPlayer and playerX and playerY then
    local dx = playerX - self.x
    local dy = playerY - self.y
    local dist = math.sqrt(dx * dx + dy * dy)
    if dist > 0 then
      local b = acquireBullet()
      b.x = bx; b.y = by
      b.vx = (dx / dist) * self.bulletSpeed
      b.vy = (dy / dist) * self.bulletSpeed
      result[1] = b
    end
  else
    local b = acquireBullet()
    b.x = bx; b.y = by
    b.vx = 0
    b.vy = self.bulletSpeed
    result[1] = b
  end

  return result
end

function Enemy:hit(damage)
  if self.shieldHp > 0 then
    self.shieldHp = self.shieldHp - 1
    return false
  end
  self.hp = self.hp - damage
  if self.hp <= 0 then
    self.alive = false
    return true
  end
  return false
end

function Enemy:draw()
  local c = cos(self.rot)
  local s = sin(self.rot)
  local px, py = self.x, self.y
  local ptCount = 0
  for i = 1, #self.verts, 2 do
    ptCount = ptCount + 1
    local vx, vy = self.verts[i], self.verts[i + 1]
    _drawPts[ptCount * 2 - 1] = px + vx * c - vy * s
    _drawPts[ptCount * 2] = py + vx * s + vy * c
  end

  local r, g, b = self.color[1], self.color[2], self.color[3]

  if self.frozen > 0 then
    r, g, b = 0.4, 0.7, 1
  end

  lg.setColor(r, g, b, 0.1)
  lg.circle("fill", px, py, self.radius + 8)
  lg.setColor(r, g, b, 0.2)
  lg.circle("fill", px, py, self.radius + 3)

  if self.shieldHp > 0 then
    lg.setColor(0.3, 0.6, 1, 0.25)
    lg.circle("fill", px, py, self.shieldRadius)
    lg.setColor(0.3, 0.6, 1, 0.5)
    lg.setLineWidth(1.5)
    lg.circle("line", px, py, self.shieldRadius)
  end

  lg.setColor(r, g, b, 0.65)
  lg.polygon("fill", _drawPts)

  lg.setColor(r, g, b, 0.25)
  lg.setLineWidth(4)
  lg.polygon("line", _drawPts)

  local lr = min(r * 1.5, 1)
  local lg2 = min(g * 1.5, 1)
  local lb = min(b * 1.5, 1)
  lg.setColor(lr, lg2, lb, 0.8)
  lg.setLineWidth(1.5)
  lg.polygon("line", _drawPts)

  lg.setColor(r * 1.3, g * 1.3, b * 1.3, 0.5)
  lg.circle("fill", px, py, self.radius * 0.3)

  if self.maxHp > 2 then
    local hpRatio = self.hp / self.maxHp
    lg.setColor(1, 1, 1, 0.2 * hpRatio)
    lg.setLineWidth(1)
    lg.circle("line", px, py, self.radius * 0.6)
    lg.circle("line", px, py, self.radius * 0.3)
  end

  lg.setColor(1, 1, 1, 1)
end

return Enemy
