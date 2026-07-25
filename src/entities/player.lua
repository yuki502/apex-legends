-- player.lua
-- Entidad del jugador: movimiento, disparo, dodge, stats, rendering.
-- Gestiona componentes instalados para modificar stats y apariencia.
-- Maneja invencibilidad temporal, flash visual, y powerups activos.
-- Los stats se calculan dinámicamente desde los componentes del hangar.

local Object = require("lib.classic")
local lume = require("lib.lume")
local ComponentDefs = require("src.data.component_defs")

local floor = math.floor
local cos = math.cos
local sin = math.sin
local min = math.min
local max = math.max
local Screen = require("src.graphics.screen")
local lg = love.graphics
local lw = Screen.getWidth
local lh = Screen.getHeight
local lgTime = love.timer.getTime

local Player = Object:extend()

local _drawVerts = {}
local _shootPos = { x = 0, y = 0 }
local _shootPosL = { x = 0, y = 0 }
local _shootPosR = { x = 0, y = 0 }
local _shootPositions = { _shootPos }

local BASE_MOVE_SPEED = 250
local DODGE_DURATION = 0.15
local DODGE_INVINCIBLE = 0.2
local DODGE_SPEED = 800
local PHASE_DODGE_DURATION = 0.25
local PHASE_DODGE_INVINCIBLE = 0.3
local HIT_INVINCIBLE = 2
local SHIELD_HIT_INVINCIBLE = 0.5
local SHOOT_COOLDOWN = 0.15
local SPEED_BOOST_MULT = 1.5
local SPEED_ITEM_MULT = 1.8

function Player:new(design, inventory)
  self.x = lw() / 2
  self.y = lh() - 80
  self.shootTimer = 0
  self.lives = 3
  self.maxLives = 3
  self.invincible = 0
  self.engineT = 0
  self.tilt = 0
  self.shieldVal = 0
  self.maxShieldVal = 0
  self.hpRegenTimer = 0
  self.dodgeTimer = 0
  self.dodgeCooldownTimer = 0
  self.isDodging = false
  self.dodgeX = 0
  self.dodgeY = 0

  self.powerups = {}
  self.inventory = inventory

  design = design or {verts = {0, -22, 14, 10, 10, 20, -10, 20, -14, 10}, color = {0.3, 0.8, 1}, accent = {0.5, 0.9, 1}, engineColor = {1, 0.5, 0.1}, radius = 18}
  self.verts = design.verts
  self.color = design.color
  self.accent = design.accent
  self.engineColor = design.engineColor
  self.radius = design.radius
  self.radiusSq = self.radius * self.radius
  self.designName = design.name or "FALCON"
end

function Player:getStats()
  return self.inventory and self.inventory:getStats() or {
    damage = 1, fireRate = 1, projectileSpeed = 1, projectileCount = 1,
    speed = 1, maxHp = 100, shield = 0, shieldRegen = 5,
    critChance = 0, dodgeCooldown = 1, hpRegen = 0, lifesteal = 0,
    ricochet = 0, homing = 0, onKillBoost = 0, dodgeTeleport = false,
    phaseDodge = false, reflect = false, beam = false, onHitRegen = 0,
    coinMultiplier = 1, acceleration = 1, turnSpeed = 1, damageReduction = 0,
  }
end

function Player:update(dt, dx, dy)
  local stats = self:getStats()
  self.engineT = self.engineT + dt * 6
  self.tilt = self.tilt + (dx * 0.3 - self.tilt) * dt * 8

  local moveSpeed = BASE_MOVE_SPEED * (stats.speed or 1)
  if self.hasSpeedBoost then moveSpeed = moveSpeed * SPEED_BOOST_MULT end
  if self.hasSpeedItem then moveSpeed = moveSpeed * SPEED_ITEM_MULT end
  self.x = self.x + dx * moveSpeed * dt
  self.y = self.y + dy * moveSpeed * dt
  local w = lw()
  local h = lh()
  self.x = lume.clamp(self.x, self.radius, w - self.radius)
  self.y = lume.clamp(self.y, self.radius, h - self.radius)

  self.shootTimer = self.shootTimer - dt
  if self.invincible > 0 then
    self.invincible = self.invincible - dt
  end

  -- Shield regen
  self.maxShieldVal = stats.shield or 0
  if self.shieldVal < self.maxShieldVal and self.invincible <= 0 then
    self.shieldVal = min(self.maxShieldVal, self.shieldVal + (stats.shieldRegen or 5) * dt)
  end

  -- HP regen
  if stats.hpRegen and stats.hpRegen > 0 then
    self.hpRegenTimer = self.hpRegenTimer + dt
    if self.hpRegenTimer >= 1 then
      self.hpRegenTimer = self.hpRegenTimer - 1
      self.lives = min(self.maxLives, self.lives + stats.hpRegen)
    end
  end

  -- Dodge cooldown
  if self.dodgeCooldownTimer > 0 then
    self.dodgeCooldownTimer = self.dodgeCooldownTimer - dt
  end

  -- Dodge state
  if self.isDodging then
    self.dodgeTimer = self.dodgeTimer - dt
    self.x = self.x + self.dodgeX * dt
    self.y = self.y + self.dodgeY * dt
    if self.dodgeTimer <= 0 then
      self.isDodging = false
    end
  end

  for name, data in pairs(self.powerups) do
    data.timer = data.timer - dt
    if data.timer <= 0 then
      self.powerups[name] = nil
      if name == "double_shot" then self.hasDoubleShot = false end
      if name == "speed" then self.hasSpeedBoost = false end
      if name == "magnet" then self.hasMagnet = false end
    end
  end
end

function Player:canShoot()
  local stats = self:getStats()
  local cooldown = SHOOT_COOLDOWN / max(0.05, stats.fireRate or 1)
  if self.shootTimer <= 0 then
    self.shootTimer = cooldown
    return true
  end
  return false
end

function Player:tryDodge(ddx, ddy)
  local stats = self:getStats()
  if self.dodgeCooldownTimer > 0 then return false end
  if self.isDodging then return false end
  self.isDodging = true
  self.dodgeTimer = DODGE_DURATION
  self.invincible = DODGE_INVINCIBLE
  self.dodgeCooldownTimer = (stats.dodgeCooldown or 1)

  if stats.phaseDodge then
    self.invincible = PHASE_DODGE_INVINCIBLE
    self.dodgeTimer = PHASE_DODGE_DURATION
  end

  local spd = DODGE_SPEED
  if ddx == 0 and ddy == 0 then ddy = -1 end
  local len = math.sqrt(ddx * ddx + ddy * ddy)
  self.dodgeX = (ddx / len) * spd
  self.dodgeY = (ddy / len) * spd
  return true
end

function Player:hit()
  if self.invincible > 0 then return false end
  local stats = self:getStats()
  if self.isDodging then return false end
  if self.shieldVal > 0 then
    self.shieldVal = self.shieldVal - 1
    self.invincible = SHIELD_HIT_INVINCIBLE
    return false
  end
  self.lives = self.lives - 1
  self.invincible = HIT_INVINCIBLE
  return true
end

function Player:getProjectileCount()
  local stats = self:getStats()
  local count = floor(stats.projectileCount or 1)
  if self.hasDoubleShot then count = count + 1 end
  return min(count, 8)
end

function Player:getShootPositions()
  local pCount = self:getProjectileCount()
  if pCount <= 1 then
    _shootPos.x = self.x
    _shootPos.y = self.y - self.radius
    _shootPositions[1] = _shootPos
    for i = 2, #_shootPositions do _shootPositions[i] = nil end
    return _shootPositions
  end
  local spread = 6 + (pCount - 2) * 4
  local startX = self.x - (pCount - 1) * spread * 0.5
  for i = 1, pCount do
    if i == 1 then
      _shootPositions[1] = _shootPositions[1] or {x=0, y=0}
      _shootPositions[1].x = startX + (i - 1) * spread
      _shootPositions[1].y = self.y - self.radius
    elseif i == 2 then
      _shootPositions[2] = _shootPositions[2] or {x=0, y=0}
      _shootPositions[2].x = startX + (i - 1) * spread
      _shootPositions[2].y = self.y - self.radius
    else
      _shootPositions[i] = _shootPositions[i] or {x=0, y=0}
      _shootPositions[i].x = startX + (i - 1) * spread
      _shootPositions[i].y = self.y - self.radius
    end
  end
  for i = pCount + 1, #_shootPositions do _shootPositions[i] = nil end
  return _shootPositions
end

function Player:collectPowerup(pType, duration)
  if pType == "heal" then
    self.lives = min(self.lives + 1, self.maxLives + 2)
    return
  end
  if pType == "shield" then
    self.shieldVal = self.maxShieldVal
    return
  end
  self.powerups[pType] = {timer = duration}
  if pType == "double_shot" then self.hasDoubleShot = true end
  if pType == "speed" then self.hasSpeedBoost = true end
  if pType == "magnet" then self.hasMagnet = true end
end

function Player:getCritChance()
  return self:getStats().critChance or 0
end

function Player:getDamageMult()
  return self:getStats().damage or 1
end

function Player:getLifesteal()
  return self:getStats().lifesteal or 0
end

function Player:getRicochet()
  return self:getStats().ricochet or 0
end

function Player:getHoming()
  return self:getStats().homing or 0
end

function Player:getCoinMultiplier()
  return self:getStats().coinMultiplier or 1
end

function Player:getDamageReduction()
  return self:getStats().damageReduction or 0
end

function Player:getOnHitRegen()
  return self:getStats().onHitRegen or 0
end

function Player:getOnKillBoost()
  return self:getStats().onKillBoost or 0
end

function Player:hasReflect()
  return self:getStats().reflect or false
end

function Player:hasBeam()
  return self:getStats().beam or false
end

function Player:getSynergies()
  return self.inventory and self.inventory:getActiveSynergies() or {}
end

local function drawComponentOnShip(verts, px, py, tilt, size, color, alpha, hollow, offsetX, offsetY)
  alpha = alpha or 1
  local c = cos(tilt)
  local s = sin(tilt)
  ox = offsetX or 0
  oy = offsetY or 0

  local cx = px + ox * c - oy * s
  local cy = py + ox * s + oy * c

  lg.push()
  lg.translate(cx, cy)
  lg.rotate(tilt)
  lg.setColor(color[1], color[2], color[3], alpha)
  if verts and #verts > 4 then
    if hollow then
      lg.setLineWidth(1.5)
      lg.polygon("line", verts)
    else
      lg.polygon("fill", verts)
    end
  else
    lg.circle("fill", 0, 0, size or 6)
  end
  lg.pop()
end

function Player:draw()
  local alpha = 1
  if self.invincible > 0 and floor(self.invincible * 10) % 2 == 0 then
    alpha = 0.35
  end

  local c = cos(self.tilt)
  local s = sin(self.tilt)
  local px, py = self.x, self.y

  local r, g, b = self.color[1], self.color[2], self.color[3]
  local ar, ag, ab = self.accent[1], self.accent[2], self.accent[3]
  local er, eg, eb = self.engineColor[1], self.engineColor[2], self.engineColor[3]

  -- Dodge flash
  if self.isDodging then
    lg.setColor(1, 1, 1, 0.15)
    lg.circle("fill", px, py, self.radius + 20)
  end

  -- Shield effect
  if self.shieldVal > 0 then
    local shieldPulse = sin(lgTime() * 4) * 0.15 + 0.35
    local shieldMax = self.maxShieldVal > 0 and self.maxShieldVal or 1
    local shieldRatio = self.shieldVal / shieldMax
    lg.setColor(0.2, 0.4 + shieldRatio * 0.4, 1, shieldPulse * alpha * 0.4)
    lg.circle("fill", px, py, self.radius + 16)
    lg.setColor(0.3, 0.5 + shieldRatio * 0.4, 1, 0.6 * alpha)
    lg.setLineWidth(2)
    lg.circle("line", px, py, self.radius + 14)
  end

  -- Ship shadow
  lg.setColor(r, g, b, alpha * 0.15)
  lg.circle("fill", px, py + 4, self.radius + 8)

  -- Engine flame
  local fl = 6 + sin(self.engineT) * 4
  local ex1x = px + (-6) * c - 20 * s
  local ex1y = py + (-6) * s + 20 * c
  local ex2x = px - (20 + fl) * s
  local ex2y = py + (20 + fl) * c
  local ex3x = px + 6 * c - 20 * s
  local ex3y = py + 6 * s + 20 * c

  lg.setColor(er, eg, eb, alpha * 0.45)
  lg.polygon("fill", ex1x, ex1y, ex2x, ex2y, ex3x, ex3y)
  lg.setColor(er, eg, eb, alpha * 0.2)
  lg.setLineWidth(2)
  lg.polygon("line", ex1x, ex1y, ex2x, ex2y, ex3x, ex3y)

  local flInner = fl * 0.6
  local ei1x = px + (-3) * c - 18 * s
  local ei1y = py + (-3) * s + 18 * c
  local ei2x = px - (18 + flInner) * s
  local ei2y = py + (18 + flInner) * c
  local ei3x = px + 3 * c - 18 * s
  local ei3y = py + 3 * s + 18 * c

  lg.setColor(er * 1.2, eg * 1.2, eb * 1.2, alpha * 0.65)
  lg.polygon("fill", ei1x, ei1y, ei2x, ei2y, ei3x, ei3y)

  -- Draw installed components on ship
  if self.inventory then
    for slotKey, pos in pairs(ComponentDefs.SLOT_LAYOUT) do
      local compId = self.inventory:getInstalled(slotKey)
      if compId then
        local compDef = ComponentDefs.ALL[compId]
        if compDef and compDef.visual then
          local color = compDef.rarityColor or compDef.color or {1,1,1}
          -- Position relative to ship center, accounting for tilt
          local ox, oy = pos.x, pos.y
          local cx = px + ox * c - oy * s
          local cy = py + ox * s + oy * c
          lg.push()
          lg.translate(cx, cy)
          lg.rotate(self.tilt)
          lg.setColor(color[1], color[2], color[3], alpha)
          local verts = compDef.visual.verts
          if verts and #verts > 4 then
            if compDef.visual.hollow then
              lg.setLineWidth(1.5)
              lg.polygon("line", verts)
            else
              lg.polygon("fill", verts)
            end
          else
            lg.circle("fill", 0, 0, compDef.visual.size or 6, 6)
          end
          lg.pop()
        end
      end
    end
  end

  -- Ship body vertices
  local vertCount = 0
  for i = 1, #self.verts, 2 do
    vertCount = vertCount + 1
    local vx, vy = self.verts[i], self.verts[i + 1]
    _drawVerts[vertCount * 2 - 1] = px + vx * c - vy * s
    _drawVerts[vertCount * 2] = py + vx * s + vy * c
  end

  lg.setColor(r * 0.4, g * 0.4, b * 0.4, alpha * 0.8)
  lg.polygon("fill", _drawVerts)

  lg.setColor(ar, ag, ab, alpha * 0.2)
  lg.setLineWidth(4)
  lg.polygon("line", _drawVerts)

  lg.setColor(ar, ag, ab, alpha * 0.9)
  lg.setLineWidth(1.5)
  lg.polygon("line", _drawVerts)

  local cx = px + 10 * s
  local cy = py - 10 * c
  lg.setColor(ar, ag, ab, alpha * 0.6)
  lg.circle("fill", cx, cy, 5)

  lg.setColor(ar * 1.2, ag * 1.2, ab * 1.2, alpha * 0.3)
  lg.circle("fill", cx, cy, 8)

  lg.setColor(1, 1, 1, 1)
end

return Player
