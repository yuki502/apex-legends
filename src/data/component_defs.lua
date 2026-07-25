local lume = require("lib.lume")

local COMPONENT_DEFS = {}

local CATEGORIES = {
  weapon = { label = "Weapon", color = {1, 0.4, 0.2} },
  thruster = { label = "Thruster", color = {0.2, 0.8, 1} },
  core = { label = "Core", color = {1, 0.2, 0.8} },
  engine = { label = "Engine", color = {0.2, 1, 0.4} },
  wing = { label = "Wing", color = {0.6, 0.4, 1} },
  shield = { label = "Shield", color = {0.2, 0.6, 1} },
  armor = { label = "Armor", color = {0.8, 0.8, 0.8} },
  multiplier = { label = "Module", color = {1, 0.8, 0.2} },
}

local RARITY_COLORS = {
  {0.7, 0.7, 0.7},
  {0.3, 0.8, 1},
  {1, 0.8, 0.2},
  {1, 0.3, 0.2},
}

local RARITY_LABELS = {"Common", "Rare", "Epic", "Legendary"}

local function def(id, data)
  data.id = id
  data.rarityColor = RARITY_COLORS[data.rarity or 1]
  data.rarityLabel = RARITY_LABELS[data.rarity or 1]
  data.color = CATEGORIES[data.slot] and CATEGORIES[data.slot].color or {1,1,1}
  COMPONENT_DEFS[id] = data
end

-- WEAPONS
def("wpn_burst", {
  name = "Burst Trigger", slot = "weapon", rarity = 1,
  desc = "Fires 3-round bursts",
  stats = { damage = 0.8, fireRate = 1.2, projectileSpeed = 1.0, projectileCount = 1 },
  visual = { verts = {0,-10, 6,0, 4,10, -4,10, -6,0}, size = 10 },
  tags = {"burst"},
})
def("wpn_spread", {
  name = "Scatter Barrel", slot = "weapon", rarity = 1,
  desc = "Fires 3 projectiles in a spread",
  stats = { damage = 0.7, fireRate = 0.9, projectileSpeed = 0.9, projectileCount = 3 },
  visual = { verts = {0,-8, 8,-2, 8,8, -8,8, -8,-2}, size = 10 },
  tags = {"spread"},
})
def("wpn_sniper", {
  name = "Rail Lance", slot = "weapon", rarity = 2,
  desc = "High damage, slow fire rate",
  stats = { damage = 2.5, fireRate = 0.4, projectileSpeed = 1.8, projectileCount = 1 },
  visual = { verts = {0,-14, 4,-2, 3,10, -3,10, -4,-2}, size = 14 },
  tags = {"sniper"},
})
def("wpn_rapid", {
  name = "Chain Gun", slot = "weapon", rarity = 2,
  desc = "Very fast fire rate, low damage",
  stats = { damage = 0.5, fireRate = 2.5, projectileSpeed = 1.0, projectileCount = 1 },
  visual = { verts = {0,-9, 5,-3, 7,0, 5,6, -5,6, -7,0, -5,-3}, size = 10 },
  tags = {"rapid"},
})
def("wpn_plasma", {
  name = "Plasma Caster", slot = "weapon", rarity = 3,
  desc = "Hitscan with burn effect",
  stats = { damage = 1.5, fireRate = 0.8, projectileSpeed = 3.0, projectileCount = 1 },
  visual = { verts = {0,-11, 7,-2, 5,11, -5,11, -7,-2}, size = 12 },
  tags = {"plasma", "energy"},
})
def("wpn_homing", {
  name = "Homing Missile", slot = "weapon", rarity = 3,
  desc = "Projectiles track enemies",
  stats = { damage = 1.2, fireRate = 0.6, projectileSpeed = 0.7, projectileCount = 1, homing = 1 },
  visual = { verts = {0,-13, 5,-4, 6,4, 3,13, -3,13, -6,4, -5,-4}, size = 13 },
  tags = {"homing"},
})
def("wpn_beam", {
  name = "Fusion Beam", slot = "weapon", rarity = 4,
  desc = "Continuous beam weapon",
  stats = { damage = 0.3, fireRate = 0.05, projectileSpeed = 0.5, projectileCount = 1, beam = true },
  visual = { verts = {0,-12, 9,-1, 7,12, -7,12, -9,-1}, size = 13 },
  tags = {"beam", "energy"},
})

-- THRUSTERS
def("thr_basic", {
  name = "Standard Thruster", slot = "thruster", rarity = 1,
  desc = "Balanced thrust",
  stats = { speed = 1.0, acceleration = 1.0 },
  visual = { verts = {-4,8, 4,8, 6,16, -6,16}, size = 10 },
})
def("thr_fast", {
  name = "Racing Thruster", slot = "thruster", rarity = 2,
  desc = "High top speed, slow acceleration",
  stats = { speed = 1.6, acceleration = 0.7 },
  visual = { verts = {-5,8, 5,8, 7,18, -7,18}, size = 12 },
})
def("thr_agile", {
  name = "Agile Thruster", slot = "thruster", rarity = 2,
  desc = "Quick acceleration",
  stats = { speed = 0.8, acceleration = 1.8 },
  visual = { verts = {-3,8, 3,8, 5,14, -5,14}, size = 9 },
})
def("thr_boost", {
  name = "Afterburner", slot = "thruster", rarity = 3,
  desc = "Speed boost on kill",
  stats = { speed = 1.3, acceleration = 1.2, onKillBoost = 2.0 },
  visual = { verts = {-5,8, 5,8, 8,20, -8,20}, size = 14 },
  tags = {"onKill"},
})
def("thr_warp", {
  name = "Warp Drive", slot = "thruster", rarity = 4,
  desc = "Short teleport on dodge",
  stats = { speed = 1.0, acceleration = 1.0, dodgeTeleport = true },
  visual = { verts = {-6,8, 6,8, 9,22, -9,22}, size = 15 },
  tags = {"dodge"},
})

-- CORES
def("core_basic", {
  name = "Stable Core", slot = "core", rarity = 1,
  desc = "Reliable energy output",
  stats = { damage = 1.0, fireRate = 1.0, maxHp = 0 },
  visual = { verts = {-6,-6, 6,-6, 8,0, 6,6, -6,6, -8,0}, size = 12 },
})
def("core_offensive", {
  name = "Fury Core", slot = "core", rarity = 2,
  desc = "+30% damage, -20% fire rate",
  stats = { damage = 1.3, fireRate = 0.8, maxHp = 0 },
  visual = { verts = {-7,-7, 7,-7, 9,0, 7,7, -7,7, -9,0}, size = 14 },
  tags = {"offensive"},
})
def("core_defensive", {
  name = "Guardian Core", slot = "core", rarity = 2,
  desc = "+50 max HP",
  stats = { damage = 0.9, fireRate = 0.9, maxHp = 50 },
  visual = { verts = {-8,-6, 8,-6, 8,6, -8,6}, size = 13 },
  tags = {"defensive"},
})
def("core_overdrive", {
  name = "Overdrive Core", slot = "core", rarity = 3,
  desc = "High risk, high reward",
  stats = { damage = 1.6, fireRate = 1.4, maxHp = -30 },
  visual = { verts = {-8,-8, 8,-8, 10,0, 8,8, -8,8, -10,0}, size = 15 },
  tags = {"offensive", "risky"},
})
def("core_omega", {
  name = "Omega Core", slot = "core", rarity = 4,
  desc = "Massive all stats boost",
  stats = { damage = 1.5, fireRate = 1.5, maxHp = 30, critChance = 0.2 },
  visual = { verts = {-9,-9, 9,-9, 11,0, 9,9, -9,9, -11,0}, size = 16 },
  tags = {"offensive", "defensive", "crit"},
})

-- ENGINES
def("eng_basic", {
  name = "Balanced Engine", slot = "engine", rarity = 1,
  desc = "Steady performance",
  stats = { speed = 1.0, turnSpeed = 1.0, dodgeCooldown = 1.0 },
  visual = { verts = {-5,-10, 5,-10, 7,0, 5,10, -5,10, -7,0}, size = 12 },
})
def("eng_turn", {
  name = "Gyro Engine", slot = "engine", rarity = 2,
  desc = "Fast turning",
  stats = { speed = 0.9, turnSpeed = 1.6, dodgeCooldown = 1.0 },
  visual = { verts = {-6,-9, 6,-9, 8,0, 6,9, -6,9, -8,0}, size = 12 },
})
def("eng_dodge", {
  name = "Dash Engine", slot = "engine", rarity = 2,
  desc = "Quick dodge cooldown",
  stats = { speed = 1.0, turnSpeed = 1.0, dodgeCooldown = 0.6 },
  visual = { verts = {-4,-11, 4,-11, 6,0, 4,11, -4,11, -6,0}, size = 12 },
  tags = {"dodge"},
})
def("eng_hybrid", {
  name = "Hybrid Engine", slot = "engine", rarity = 3,
  desc = "Balanced + speed boost",
  stats = { speed = 1.3, turnSpeed = 1.2, dodgeCooldown = 0.8 },
  visual = { verts = {-6,-11, 6,-11, 9,0, 6,11, -6,11, -9,0}, size = 13 },
})
def("eng_quantum", {
  name = "Quantum Engine", slot = "engine", rarity = 4,
  desc = "Phase dodge + fast all",
  stats = { speed = 1.4, turnSpeed = 1.4, dodgeCooldown = 0.4, phaseDodge = true },
  visual = { verts = {-7,-12, 7,-12, 10,0, 7,12, -7,12, -10,0}, size = 14 },
  tags = {"dodge", "phase"},
})

-- WINGS
def("wng_balanced", {
  name = "Balanced Wing", slot = "wing", rarity = 1,
  desc = "Minor all-around boost",
  stats = { damage = 1.05, speed = 1.05, maxHp = 10 },
  visual = { verts = {-14,-2, -6,-6, -6,6, -14,2}, size = 8 },
})
def("wng_aggressive", {
  name = "Strike Wing", slot = "wing", rarity = 2,
  desc = "+15% damage",
  stats = { damage = 1.15, speed = 0.95, maxHp = 5 },
  visual = { verts = {-16,-3, -7,-7, -7,7, -16,3}, size = 9 },
  tags = {"offensive"},
})
def("wng_deflector", {
  name = "Deflector Wing", slot = "wing", rarity = 2,
  desc = "+25 HP, small shield regen",
  stats = { damage = 1.0, speed = 0.95, maxHp = 25, shieldRegen = 1 },
  visual = { verts = {-15,-4, -5,-8, -5,8, -15,4}, size = 9 },
  tags = {"defensive"},
})
def("wng_aero", {
  name = "Aero Wing", slot = "wing", rarity = 3,
  desc = "Fast and agile",
  stats = { damage = 1.0, speed = 1.2, maxHp = 10 },
  visual = { verts = {-17,-2, -6,-5, -6,5, -17,2}, size = 9 },
  tags = {"speed"},
})
def("wng_photon", {
  name = "Photon Wing", slot = "wing", rarity = 4,
  desc = "Extra projectile + boost all",
  stats = { damage = 1.1, speed = 1.1, maxHp = 20, projectileCount = 1 },
  visual = { verts = {-18,-3, -7,-8, -7,8, -18,3}, size = 10 },
  tags = {"offensive", "energy"},
})

-- SHIELDS
def("shd_basic", {
  name = "Standard Shield", slot = "shield", rarity = 1,
  desc = "Basic shield bubble",
  stats = { shield = 30, shieldRegen = 5 },
  visual = { verts = {-8,-8, 8,-8, 10,0, 8,8, -8,8, -10,0}, size = 11, hollow = true },
})
def("shd_heavy", {
  name = "Heavy Shield", slot = "shield", rarity = 2,
  desc = "High capacity, slow regen",
  stats = { shield = 60, shieldRegen = 3 },
  visual = { verts = {-10,-10, 10,-10, 12,0, 10,10, -10,10, -12,0}, size = 13, hollow = true },
})
def("shd_fast", {
  name = "Quick Shield", slot = "shield", rarity = 2,
  desc = "Low capacity, fast regen",
  stats = { shield = 20, shieldRegen = 10 },
  visual = { verts = {-7,-7, 7,-7, 9,0, 7,7, -7,7, -9,0}, size = 10, hollow = true },
})
def("shd_absorber", {
  name = "Energy Absorber", slot = "shield", rarity = 3,
  desc = "Shield recharges on hit",
  stats = { shield = 40, shieldRegen = 4, onHitRegen = 5 },
  visual = { verts = {-9,-9, 9,-9, 11,0, 9,9, -9,9, -11,0}, size = 12, hollow = true },
  tags = {"onHit"},
})
def("shd_prism", {
  name = "Prism Barrier", slot = "shield", rarity = 4,
  desc = "Shield reflects projectiles",
  stats = { shield = 50, shieldRegen = 6, reflect = true },
  visual = { verts = {-11,-11, 11,-11, 13,0, 11,11, -11,11, -13,0}, size = 14, hollow = true },
  tags = {"reflect"},
})

-- ARMOR
def("arm_light", {
  name = "Light Plating", slot = "armor", rarity = 1,
  desc = "Minimal weight, some HP",
  stats = { maxHp = 20, damageReduction = 0 },
  visual = { verts = {-7,-6, 7,-6, 9,0, 7,6, -7,6, -9,0}, size = 10 },
})
def("arm_heavy", {
  name = "Heavy Plating", slot = "armor", rarity = 2,
  desc = "80 HP, slows ship",
  stats = { maxHp = 80, damageReduction = 0.05, speedMult = 0.85 },
  visual = { verts = {-9,-8, 9,-8, 11,0, 9,8, -9,8, -11,0}, size = 13 },
  tags = {"defensive", "heavy"},
})
def("arm_reactive", {
  name = "Reactive Armor", slot = "armor", rarity = 3,
  desc = "Reduces damage on hit streaks",
  stats = { maxHp = 40, damageReduction = 0.1 },
  visual = { verts = {-8,-7, 8,-7, 10,0, 8,7, -8,7, -10,0}, size = 11 },
  tags = {"defensive"},
})
def("arm_carbon", {
  name = "Carbon Fiber", slot = "armor", rarity = 3,
  desc = "Light and strong",
  stats = { maxHp = 50, damageReduction = 0.08, speedMult = 1.05 },
  visual = { verts = {-7,-7, 7,-7, 9,0, 7,7, -7,7, -9,0}, size = 11 },
})
def("arm_void", {
  name = "Void Alloy", slot = "armor", rarity = 4,
  desc = "Massive HP + damage reduction",
  stats = { maxHp = 120, damageReduction = 0.15 },
  visual = { verts = {-10,-9, 10,-9, 12,0, 10,9, -10,9, -12,0}, size = 14 },
  tags = {"defensive"},
})

-- MULTIPLIERS (MODULES)
def("mod_dmg", {
  name = "Damage Amplifier", slot = "multiplier", rarity = 1,
  desc = "+12% damage",
  stats = { damageMult = 1.12 },
  visual = { verts = {-5,-5, 5,-5, 6,0, 5,5, -5,5, -6,0}, size = 7 },
  tags = {"offensive"},
})
def("mod_firerate", {
  name = "Overclock Module", slot = "multiplier", rarity = 1,
  desc = "+12% fire rate",
  stats = { fireRateMult = 1.12 },
  visual = { verts = {-5,-5, 5,-5, 6,0, 5,5, -5,5, -6,0}, size = 7 },
  tags = {"offensive"},
})
def("mod_speed", {
  name = "Accelerator", slot = "multiplier", rarity = 2,
  desc = "+15% speed",
  stats = { speedMult = 1.15 },
  visual = { verts = {-5,-5, 5,-5, 7,0, 5,5, -5,5, -7,0}, size = 8 },
  tags = {"speed"},
})
def("mod_hp", {
  name = "HP Booster", slot = "multiplier", rarity = 1,
  desc = "+30 max HP",
  stats = { maxHp = 30 },
  visual = { verts = {-5,-5, 5,-5, 6,0, 5,5, -5,5, -6,0}, size = 7 },
  tags = {"defensive"},
})
def("mod_shield", {
  name = "Shield Amplifier", slot = "multiplier", rarity = 2,
  desc = "+20 shield capacity",
  stats = { shield = 20 },
  visual = { verts = {-5,-5, 5,-5, 7,0, 5,5, -5,5, -7,0}, size = 8 },
  tags = {"defensive"},
})
def("mod_crit", {
  name = "Crit Module", slot = "multiplier", rarity = 3,
  desc = "+10% crit chance",
  stats = { critChance = 0.1 },
  visual = { verts = {-6,-6, 6,-6, 8,0, 6,6, -6,6, -8,0}, size = 9 },
  tags = {"offensive", "crit"},
})
def("mod_coin", {
  name = "Coin Magnet", slot = "multiplier", rarity = 2,
  desc = "2x coin pickup range",
  stats = { coinMultiplier = 2.0 },
  visual = { verts = {-5,-5, 5,-5, 6,0, 5,5, -5,5, -6,0}, size = 7 },
  tags = {"economy"},
})
def("mod_regen", {
  name = "Repair Module", slot = "multiplier", rarity = 3,
  desc = "Regen 1 HP/sec",
  stats = { hpRegen = 1 },
  visual = { verts = {-6,-6, 6,-6, 8,0, 6,6, -6,6, -8,0}, size = 9 },
  tags = {"defensive"},
})
def("mod_ricochet", {
  name = "Ricochet Chip", slot = "multiplier", rarity = 4,
  desc = "Bullets bounce off walls",
  stats = { ricochet = 2 },
  visual = { verts = {-7,-7, 7,-7, 9,0, 7,7, -7,7, -9,0}, size = 10 },
  tags = {"offensive", "chaos"},
})
def("mod_lifesteal", {
  name = "Lifesteal Module", slot = "multiplier", rarity = 4,
  desc = "Heal 3% of damage dealt",
  stats = { lifesteal = 0.03 },
  visual = { verts = {-7,-7, 7,-7, 9,0, 7,7, -7,7, -9,0}, size = 10 },
  tags = {"offensive", "defensive"},
})

-- SLOT LAYOUT
local SLOT_LAYOUT = {
  weapon = { label = "Weapon", max = 1, x = 0, y = -35 },
  thruster = { label = "Thruster", max = 1, x = 0, y = 35 },
  core = { label = "Core", max = 1, x = 0, y = 0 },
  engine = { label = "Engine", max = 1, x = 0, y = 18 },
  wing = { label = "Wing L", max = 2, x = -25, y = -10, slotKey = "wing" },
  wing2 = { label = "Wing R", max = 2, x = 25, y = -10, slotKey = "wing" },
  shield = { label = "Shield", max = 1, x = 0, y = -18 },
  armor = { label = "Armor", max = 1, x = 0, y = 10 },
  multiplier = { label = "Module 1", max = 3, x = -16, y = 28, slotKey = "multiplier" },
  multiplier2 = { label = "Module 2", max = 3, x = 0, y = 28, slotKey = "multiplier" },
  multiplier3 = { label = "Module 3", max = 3, x = 16, y = 28, slotKey = "multiplier" },
}

local SLOT_CATEGORIES = {
  weapon = "weapon",
  thruster = "thruster",
  core = "core",
  engine = "engine",
  wing = "wing",
  wing2 = "wing",
  shield = "shield",
  armor = "armor",
  multiplier = "multiplier",
  multiplier2 = "multiplier",
  multiplier3 = "multiplier",
}

return {
  ALL = COMPONENT_DEFS,
  CATEGORIES = CATEGORIES,
  RARITY_COLORS = RARITY_COLORS,
  RARITY_LABELS = RARITY_LABELS,
  SLOT_LAYOUT = SLOT_LAYOUT,
  SLOT_CATEGORIES = SLOT_CATEGORIES,
  get = function(id) return COMPONENT_DEFS[id] end,
  getBySlot = function(slot)
    local result = {}
    for id, c in pairs(COMPONENT_DEFS) do
      if c.slot == slot then
        result[#result + 1] = c
      end
    end
    return result
  end,
  getByRarity = function(rarity)
    local result = {}
    for id, c in pairs(COMPONENT_DEFS) do
      if c.rarity == rarity then
        result[#result + 1] = c
      end
    end
    return result
  end,
  getRandomBySlot = function(slot, wave)
    -- Picks a random component for the given slot, weighted by wave:
    -- higher waves unlock higher rarities (1 per 10 waves, up to 4).
    -- Rarity weight is 1 + rarity * 0.3 so rarer items appear more at higher waves.
    local candidates = {}
    for id, c in pairs(COMPONENT_DEFS) do
      if c.slot == slot then
        local maxRarity = math.min(4, 1 + math.floor(wave / 10))
        if c.rarity <= maxRarity then
          candidates[#candidates + 1] = c
        end
      end
    end
    if #candidates == 0 then return nil end
    -- weight toward higher rarity at higher waves
    local weights = {}
    for i, c in ipairs(candidates) do
      weights[i] = 1 + c.rarity * 0.3
    end
    local total = 0
    for _, w in ipairs(weights) do total = total + w end
    local r = lume.random(0, total)
    local acc = 0
    for i, w in ipairs(weights) do
      acc = acc + w
      if r <= acc then return candidates[i] end
    end
    return candidates[#candidates]
  end,
  getAllSlotKeys = function()
    local keys = {}
    for k in pairs(SLOT_LAYOUT) do keys[#keys + 1] = k end
    return keys
  end,
}
