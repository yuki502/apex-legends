local Object = require("lib.classic")
local lume = require("lib.lume")
local flux = require("lib.flux")

local sin = math.sin
local cos = math.cos
local lg = love.graphics
local lw = lg.getWidth
local lh = lg.getHeight

local Effects = Object:extend()

local MAX_PARTICLES = 256
local MAX_TEXTS = 32

function Effects:new()
  self.stars = {}
  self.particles = {}
  self.particleCount = 0
  self.texts = {}
  self.textCount = 0
  self.tweens = flux.group()
  self._particlePool = {}
  self._particlePoolCount = 0
  self._textPool = {}
  self._textPoolCount = 0

  for i = 1, MAX_PARTICLES do
    self._particlePool[i] = {
      x=0, y=0, vx=0, vy=0, life=0, maxLife=0, color={0,0,0}, size=0
    }
    self._particlePoolCount = MAX_PARTICLES
  end
  for i = 1, MAX_TEXTS do
    self._textPool[i] = {
      x=0, y=0, text="", color={0,0,0}, life=0, fadeTime=0, alpha=0, scale=1
    }
    self._textPoolCount = MAX_TEXTS
  end

  local w = lw()
  local h = lh()
  for i = 1, 80 do
    self.stars[i] = {
      x = lume.random(0, w),
      y = lume.random(0, h),
      speed = lume.random(20, 80),
      size = lume.random(1, 3),
      brightness = lume.random(0.3, 1),
    }
  end
end

local function acquireParticle(self)
  if self._particlePoolCount > 0 then
    local p = self._particlePool[self._particlePoolCount]
    self._particlePool[self._particlePoolCount] = nil
    self._particlePoolCount = self._particlePoolCount - 1
    return p
  end
  return {x=0, y=0, vx=0, vy=0, life=0, maxLife=0, color={0,0,0}, size=0}
end

local function releaseParticle(self, p)
  self._particlePoolCount = self._particlePoolCount + 1
  self._particlePool[self._particlePoolCount] = p
end

local function acquireText(self)
  if self._textPoolCount > 0 then
    local t = self._textPool[self._textPoolCount]
    self._textPool[self._textPoolCount] = nil
    self._textPoolCount = self._textPoolCount - 1
    return t
  end
  return {x=0, y=0, text="", color={0,0,0}, life=0, fadeTime=0, alpha=0, scale=1}
end

local function releaseText(self, t)
  self._textPoolCount = self._textPoolCount + 1
  self._textPool[self._textPoolCount] = t
end

function Effects:update(dt)
  self.tweens:update(dt)
  local w = lw()
  local h = lh()
  for i = 1, #self.stars do
    local star = self.stars[i]
    star.y = star.y + star.speed * dt
    if star.y > h then
      star.y = -2
      star.x = lume.random(0, w)
    end
  end

  local i = 1
  while i <= self.particleCount do
    local p = self.particles[i]
    p.x = p.x + p.vx * dt
    p.y = p.y + p.vy * dt
    p.vy = p.vy + 120 * dt
    p.life = p.life - dt
    if p.life <= 0 then
      releaseParticle(self, p)
      self.particles[i] = self.particles[self.particleCount]
      self.particles[self.particleCount] = nil
      self.particleCount = self.particleCount - 1
    else
      i = i + 1
    end
  end

  i = 1
  while i <= self.textCount do
    local t = self.texts[i]
    t.y = t.y - 40 * dt
    t.life = t.life - dt
    t.alpha = t.life < t.fadeTime and t.life / t.fadeTime or 1
    if t.life <= 0 then
      releaseText(self, t)
      self.texts[i] = self.texts[self.textCount]
      self.texts[self.textCount] = nil
      self.textCount = self.textCount - 1
    else
      i = i + 1
    end
  end
end

function Effects:spawnParticles(x, y, color, count, speed, vxOff, vyOff)
  count = count or 12
  speed = speed or 180
  color = color or {1, 0.3, 0.2}
  vxOff = vxOff or 0
  vyOff = vyOff or 0
  for i = 1, count do
    if self.particleCount >= MAX_PARTICLES then break end
    local angle = lume.random(0, 6.2832)
    local spd = lume.random(speed * 0.5, speed)
    local p = acquireParticle(self)
    p.x = x; p.y = y
    p.vx = cos(angle) * spd + vxOff
    p.vy = sin(angle) * spd + vyOff
    p.life = lume.random(0.3, 0.8)
    p.maxLife = 0.8
    p.color = color
    p.size = lume.random(2, 5)
    self.particleCount = self.particleCount + 1
    self.particles[self.particleCount] = p
  end
end

function Effects:explode(x, y, color, count, speed)
  self:spawnParticles(x, y, color, count, speed)
end

function Effects:muzzleFlash(x, y)
  if self.particleCount >= MAX_PARTICLES then return end
  for i = 1, 4 do
    local angle = -1.5708 + lume.random(-0.4, 0.4)
    local spd = lume.random(100, 250)
    local p = acquireParticle(self)
    p.x = x; p.y = y
    p.vx = cos(angle) * spd
    p.vy = sin(angle) * spd
    p.life = lume.random(0.05, 0.15)
    p.maxLife = 0.15
    p.color = {1, 0.9, 0.4}
    p.size = lume.random(1, 3)
    self.particleCount = self.particleCount + 1
    self.particles[self.particleCount] = p
  end
end

function Effects:powerupCollect(x, y, color)
  self:spawnParticles(x, y, color, 20, 160)
  if self.textCount < MAX_TEXTS then
    local t = acquireText(self)
    t.x = x; t.y = y - 20
    t.text = "POWER UP!"
    t.color = color
    t.life = 1.0
    t.fadeTime = 0.5
    t.alpha = 1
    t.scale = 1.2
    self.textCount = self.textCount + 1
    self.texts[self.textCount] = t
  end
end

function Effects:waveAnnounce(wave, bossWave)
  local w = lw()
  local text = bossWave and ("BOSS WAVE " .. wave) or ("WAVE " .. wave)
  local color = bossWave and {1, 0.3, 0.2} or {0.3, 0.8, 1}
  if self.textCount < MAX_TEXTS then
    local t = acquireText(self)
    t.x = w / 2
    t.y = lh() / 2 - 40
    t.text = text
    t.color = color
    t.life = 2.0
    t.fadeTime = 1.0
    t.alpha = 1
    t.scale = 1.5
    self.textCount = self.textCount + 1
    self.texts[self.textCount] = t
  end
end

function Effects:comboText(x, y, combo)
  local color
  if combo >= 10 then
    color = {1, 0.2, 0.8}
  elseif combo >= 5 then
    color = {1, 0.8, 0.2}
  else
    color = {0.3, 1, 0.6}
  end
  if self.textCount < MAX_TEXTS then
    local t = acquireText(self)
    t.x = x; t.y = y - 30
    t.text = "x" .. combo
    t.color = color
    t.life = 0.8
    t.fadeTime = 0.4
    t.alpha = 1
    t.scale = 1.0 + combo * 0.05
    self.textCount = self.textCount + 1
    self.texts[self.textCount] = t
  end
end

function Effects:coinPickup(x, y)
  self:spawnParticles(x, y, {1, 0.85, 0.2}, 6, 100)
end

function Effects:installComponent(x, y, color)
  self:spawnParticles(x, y, color, 16, 150)
end

function Effects:tweenValue(obj, time, vars)
  return self.tweens:to(obj, time, vars)
end

function Effects:draw()
  for i = 1, #self.stars do
    local star = self.stars[i]
    local a = star.brightness
    lg.setColor(a, a, a, a * 0.8)
    lg.circle("fill", star.x, star.y, star.size)
  end
  for i = 1, self.particleCount do
    local p = self.particles[i]
    local a = p.life / p.maxLife
    local r, g, b = p.color[1], p.color[2], p.color[3]
    lg.setColor(r, g, b, a)
    lg.circle("fill", p.x, p.y, p.size * a)
    lg.setColor(r, g, b, a * 0.3)
    lg.circle("fill", p.x, p.y, p.size * a * 2)
  end
  local font = lg.getFont()
  for i = 1, self.textCount do
    local t = self.texts[i]
    local r, g, b = t.color[1], t.color[2], t.color[3]
    lg.setColor(r, g, b, t.alpha)
    lg.push()
    lg.translate(t.x, t.y)
    lg.scale(t.scale, t.scale)
    local fw = font:getWidth(t.text)
    lg.print(t.text, -fw / 2, -8)
    lg.pop()
  end
end

return Effects
