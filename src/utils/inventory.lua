-- inventory.lua
-- Gestión de inventario de componentes del jugador.
-- Maneja: componentes poseídos, instalados en slots, créditos.
-- Persiste entre partidas via inventory.dat.
-- Soporta: instalar/desinstalar componentes, agregar/quitar créditos.

local Object = require("lib.classic")
local ComponentDefs = require("src.data.component_defs")

local Inventory = Object:extend()

function Inventory:new()
  self.owned = {}
  self.installed = {}
  self.credits = 0
  self:reset()
end

function Inventory:reset()
  self.owned = {}
  self.installed = {}
  for slotKey, slotInfo in pairs(ComponentDefs.SLOT_LAYOUT) do
    self.installed[slotKey] = nil
  end
  -- start with basic components
  self:add("wpn_burst")
  self:add("thr_basic")
  self:add("core_basic")
  self:add("eng_basic")
  self:add("wng_balanced")
  self:add("wng_balanced")
  self:add("shd_basic")
  self:add("arm_light")
  -- auto-install basics
  self:install("weapon", "wpn_burst")
  self:install("thruster", "thr_basic")
  self:install("core", "core_basic")
  self:install("engine", "eng_basic")
  self:install("wing", "wng_balanced")
  self:install("wing2", "wng_balanced")
  self:install("shield", "shd_basic")
  self:install("armor", "arm_light")
end

function Inventory:add(componentId)
  if not ComponentDefs.ALL[componentId] then return false end
  if not self.owned[componentId] then
    self.owned[componentId] = 0
  end
  self.owned[componentId] = self.owned[componentId] + 1
  return true
end

function Inventory:remove(componentId)
  if not self.owned[componentId] or self.owned[componentId] <= 0 then return false end
  self.owned[componentId] = self.owned[componentId] - 1
  if self.owned[componentId] <= 0 then
    self.owned[componentId] = nil
  end
  return true
end

function Inventory:count(componentId)
  return self.owned[componentId] or 0
end

function Inventory:getInstalled(slotKey)
  return self.installed[slotKey]
end

function Inventory:install(slotKey, componentId)
  local def = ComponentDefs.ALL[componentId]
  if not def then return false end

  local slotCat = ComponentDefs.SLOT_CATEGORIES[slotKey]
  if not slotCat then return false end
  if def.slot ~= slotCat then return false end

  if not self.owned[componentId] or self.owned[componentId] <= 0 then return false end

  local oldId = self.installed[slotKey]
  if oldId == componentId then return false end

  self:remove(componentId)
  self.installed[slotKey] = componentId

  if oldId then
    self:add(oldId)
  end

  return true, oldId
end

function Inventory:uninstall(slotKey)
  local oldId = self.installed[slotKey]
  if not oldId then return false end
  self.installed[slotKey] = nil
  self:add(oldId)
  return true
end

function Inventory:getStats()
  local stats = {
    damage = 1.0,
    fireRate = 1.0,
    projectileSpeed = 1.0,
    projectileCount = 1,
    speed = 1.0,
    turnSpeed = 1.0,
    acceleration = 1.0,
    maxHp = 100,
    shield = 0,
    shieldRegen = 5,
    damageReduction = 0,
    critChance = 0,
    dodgeCooldown = 1.0,
    coinMultiplier = 1.0,
    hpRegen = 0,
    lifesteal = 0,
    ricochet = 0,
    homing = 0,
    onKillBoost = 0,
    dodgeTeleport = false,
    phaseDodge = false,
    reflect = false,
    beam = false,
    onHitRegen = 0,
  }

  for slotKey, compId in pairs(self.installed) do
    local def = ComponentDefs.ALL[compId]
    if def and def.stats then
      for k, v in pairs(def.stats) do
        if type(v) == "number" then
          stats[k] = (stats[k] or 0) + v
        elseif type(v) == "boolean" then
          stats[k] = v
        end
      end
    end
  end

  -- apply multipliers multiplicatively
  local dmgMult = 1.0
  local frMult = 1.0
  local spdMult = 1.0
  for slotKey, compId in pairs(self.installed) do
    local def = ComponentDefs.ALL[compId]
    if def and def.stats then
      if def.stats.damageMult then dmgMult = dmgMult * def.stats.damageMult end
      if def.stats.fireRateMult then frMult = frMult * def.stats.fireRateMult end
      if def.stats.speedMult then spdMult = spdMult * def.stats.speedMult end
    end
  end
  stats.damage = stats.damage * dmgMult
  stats.fireRate = stats.fireRate * frMult
  stats.speed = stats.speed * spdMult

  -- projectileCount is additive from wings/weapons
  -- Ensure minimums
  stats.damage = math.max(0.1, stats.damage)
  stats.fireRate = math.max(0.05, stats.fireRate)
  stats.maxHp = math.max(10, stats.maxHp)
  stats.speed = math.max(0.3, stats.speed)

  return stats
end

function Inventory:getActiveSynergies()
  local installed = {}
  for slotKey, compId in pairs(self.installed) do
    if compId then
      installed[#installed + 1] = ComponentDefs.ALL[compId]
    end
  end
  local SynergySystem = require("src.systems.synergy_system")
  return SynergySystem.check(installed)
end

function Inventory:getOwnedList()
  local list = {}
  for id, count in pairs(self.owned) do
    if count > 0 then
      list[#list + 1] = { id = id, count = count, def = ComponentDefs.ALL[id] }
    end
  end
  table.sort(list, function(a, b)
    local da, db = a.def, b.def
    if da.rarity ~= db.rarity then return da.rarity > db.rarity end
    return da.name < db.name
  end)
  return list
end

function Inventory:getInstalledList()
  local list = {}
  for slotKey, compId in pairs(self.installed) do
    if compId then
      list[#list + 1] = { slotKey = slotKey, id = compId, def = ComponentDefs.ALL[compId] }
    end
  end
  return list
end

function Inventory:getSlotInstalled(slotKey)
  local id = self.installed[slotKey]
  if id then return id, ComponentDefs.ALL[id] end
  return nil, nil
end

function Inventory:addCredits(amount)
  self.credits = self.credits + amount
end

function Inventory:spendCredits(amount)
  if self.credits >= amount then
    self.credits = self.credits - amount
    return true
  end
  return false
end

return Inventory
