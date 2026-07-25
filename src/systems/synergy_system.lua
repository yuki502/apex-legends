-- synergy_system.lua
-- Sistema de sinergias: 14+ combinaciones de componentes.
-- Cada sinergia requiere una combinación específica de componentes.
-- Se evalúan cada frame basándose en los componentes instalados.
-- Las sinergies activas otorgan bonus estadísticos.

local SYNERGIES = {}

--- Registra una nueva sinergia.
-- @param id Identificador único
-- @param name Nombre para mostrar
-- @param checkFn Función de verificación: function(components) → boolean
local function add(id, name, desc, color, checkFn)
  SYNERGIES[id] = {
    name = name,
    desc = desc,
    color = color,
    check = checkFn,
  }
end

-- Component category presence synergies
add("full_weapon", "Arsenal", "3+ weapon-type components", {1, 0.3, 0.2},
  function(comps)
    local count = 0
    for _, c in ipairs(comps) do
      if c.slot == "weapon" then count = count + 1 end
    end
    return count >= 3
  end)

add("full_defense", "Fortress", "Shield + Armor + HP module", {0.3, 0.8, 1},
  function(comps)
    local hasShield, hasArmor, hasHP = false, false, false
    for _, c in ipairs(comps) do
      if c.slot == "shield" then hasShield = true end
      if c.slot == "armor" then hasArmor = true end
      if c.id == "mod_hp" then hasHP = true end
    end
    return hasShield and hasArmor and hasHP
  end)

add("speed_demon", "Speed Demon", "Thruster + Engine + speed module", {0.2, 1, 0.4},
  function(comps)
    local hasT, hasE, hasS = false, false, false
    for _, c in ipairs(comps) do
      if c.slot == "thruster" then hasT = true end
      if c.slot == "engine" then hasE = true end
      if c.id == "mod_speed" then hasS = true end
    end
    return hasT and hasE and hasS
  end)

-- Tag-based synergies
add("energy_master", "Energy Master", "3+ energy-tagged components", {0.4, 0.6, 1},
  function(comps)
    local count = 0
    for _, c in ipairs(comps) do
      if c.tags then
        for _, t in ipairs(c.tags) do
          if t == "energy" then count = count + 1; break end
        end
      end
    end
    return count >= 3
  end)

add("crit_master", "Precision Striker", "2+ crit-tagged components", {1, 0.8, 0.2},
  function(comps)
    local count = 0
    for _, c in ipairs(comps) do
      if c.tags then
        for _, t in ipairs(c.tags) do
          if t == "crit" then count = count + 1; break end
        end
      end
    end
    return count >= 2
  end)

add("dodge_master", "Ghost", "2+ dodge-tagged components", {0.5, 0.3, 1},
  function(comps)
    local count = 0
    for _, c in ipairs(comps) do
      if c.tags then
        for _, t in ipairs(c.tags) do
          if t == "dodge" then count = count + 1; break end
        end
      end
    end
    return count >= 2
  end)

-- Rarity-based synergies
add("legendary_power", "Legendary Force", "2+ legendary components", {1, 0.3, 0.2},
  function(comps)
    local count = 0
    for _, c in ipairs(comps) do
      if c.rarity == 4 then count = count + 1 end
    end
    return count >= 2
  end)

-- Specific component combos
add("plasma_overload", "Plasma Overload", "Plasma Caster + Fusion Beam", {1, 0.4, 0.6},
  function(comps)
    local hasPlasma, hasBeam = false, false
    for _, c in ipairs(comps) do
      if c.id == "wpn_plasma" then hasPlasma = true end
      if c.id == "wpn_beam" then hasBeam = true end
    end
    return hasPlasma and hasBeam
  end)

add("ricochet_carnage", "Ricochet Carnage", "Ricochet Chip + Scatter Barrel", {1, 0.6, 0.2},
  function(comps)
    hasRicochet, hasScatter = false, false
    for _, c in ipairs(comps) do
      if c.id == "mod_ricochet" then hasRicochet = true end
      if c.id == "wpn_spread" then hasScatter = true end
    end
    return hasRicochet and hasScatter
  end)

add("vampire_build", "Vampire", "Lifesteal + Reactive Armor", {0.8, 0.2, 0.2},
  function(comps)
    local hasLife, hasReact = false, false
    for _, c in ipairs(comps) do
      if c.id == "mod_lifesteal" then hasLife = true end
      if c.id == "arm_reactive" then hasReact = true end
    end
    return hasLife and hasReact
  end)

add("omega_boost", "Omega Drive", "Omega Core + Quantum Engine", {0.6, 0.3, 1},
  function(comps)
    local hasOmega, hasQuantum = false, false
    for _, c in ipairs(comps) do
      if c.id == "core_omega" then hasOmega = true end
      if c.id == "eng_quantum" then hasQuantum = true end
    end
    return hasOmega and hasQuantum
  end)

-- Economy synergy
add("scrooge", "Scrooge", "3+ economy-tagged components", {1, 0.85, 0.2},
  function(comps)
    local count = 0
    for _, c in ipairs(comps) do
      if c.tags then
        for _, t in ipairs(c.tags) do
          if t == "economy" then count = count + 1; break end
        end
      end
    end
    return count >= 3
  end)

-- All offensive synergy
add("pure_offense", "Pure Offense", "4+ offensive-tagged components", {1, 0.3, 0.2},
  function(comps)
    local count = 0
    for _, c in ipairs(comps) do
      if c.tags then
        for _, t in ipairs(c.tags) do
          if t == "offensive" then count = count + 1; break end
        end
      end
    end
    return count >= 4
  end)

-- All defensive synergy
add("impregnable", "Impregnable", "4+ defensive-tagged components", {0.2, 0.6, 1},
  function(comps)
    local count = 0
    for _, c in ipairs(comps) do
      if c.tags then
        for _, t in ipairs(c.tags) do
          if t == "defensive" then count = count + 1; break end
        end
      end
    end
    return count >= 4
  end)

local SynergySystem = {}

function SynergySystem.check(components)
  local active = {}
  for id, syn in pairs(SYNERGIES) do
    if syn.check(components) then
      active[#active + 1] = {
        name = syn.name,
        desc = syn.desc,
        color = syn.color,
        id = id,
      }
    end
  end
  table.sort(active, function(a, b) return a.name < b.name end)
  return active
end

function SynergySystem.getAll()
  local list = {}
  for id, syn in pairs(SYNERGIES) do
    list[#list + 1] = { id = id, name = syn.name, desc = syn.desc, color = syn.color }
  end
  return list
end

return SynergySystem
