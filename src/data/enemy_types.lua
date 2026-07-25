-- enemy_types.lua
-- Definición de 10 tipos de enemigos con comportamientos distintos.
-- Cada tipo tiene: nombre, vértices, color, hp, radius, speed, damage, behavior.
-- Los comportamientos: straight, dodge, strafe, zonal, sniper, kamikaze, tank, bomber, dash, shield.
-- Escalado por ola: hp ×1.06, damage ×1.04, speed ×1.02.

local EnemyTypes = {}

-- Definición de tipos de enemigos
EnemyTypes.DEF = {
  scout = {
    name = "scout",
    verts = {0, -16, 16, 0, 0, 16, -16, 0},
    color = {1, 0.2, 0.2},
    hp = 1,
    radius = 16,
    speed = {80, 140},
    points = 10,
    xp = 5,
    credits = 2,
    shootChance = 0,
    behavior = "straight",
    sineAmp = {0, 30},
    sineFreq = {1, 3},
    minWave = 1,
    weight = 10,
  },
  interceptor = {
    name = "interceptor",
    verts = {0, -14, 10, -6, 14, 6, 6, 14, -6, 14, -14, 6, -10, -6},
    color = {0.2, 0.8, 0.8},
    hp = 1,
    radius = 14,
    speed = {120, 180},
    points = 12,
    xp = 6,
    credits = 3,
    shootChance = 0,
    behavior = "dodge",
    sineAmp = {0, 15},
    sineFreq = {2, 5},
    minWave = 1,
    weight = 8,
  },
  trooper = {
    name = "trooper",
    verts = {0, -18, 15, -9, 15, 9, 0, 18, -15, 9, -15, -9},
    color = {0.5, 0.2, 1},
    hp = 2,
    radius = 18,
    speed = {70, 120},
    points = 20,
    xp = 10,
    credits = 5,
    shootChance = 0.15,
    behavior = "strafe",
    sineAmp = {20, 50},
    sineFreq = {0.8, 2},
    minWave = 3,
    weight = 7,
  },
  gunner = {
    name = "gunner",
    verts = {0, -20, 18, 16, -18, 16},
    color = {1, 0.6, 0},
    hp = 2,
    radius = 14,
    speed = {60, 100},
    points = 25,
    xp = 12,
    credits = 6,
    shootChance = 0.4,
    behavior = "zonal",
    shootPattern = "burst",
    burstCount = 3,
    burstDelay = 0.12,
    sineAmp = {10, 25},
    sineFreq = {0.5, 1.5},
    minWave = 5,
    weight = 5,
  },
  sniper = {
    name = "sniper",
    verts = {0, -22, 6, -8, 14, 0, 6, 8, 0, 22, -6, 8, -14, 0, -6, -8},
    color = {0.2, 1, 0.4},
    hp = 1,
    radius = 15,
    speed = {30, 60},
    points = 30,
    xp = 15,
    credits = 8,
    shootChance = 0.6,
    behavior = "sniper",
    aimAtPlayer = true,
    bulletSpeed = 250,
    sineAmp = {0, 5},
    sineFreq = {0.3, 0.8},
    minWave = 7,
    weight = 4,
  },
  kamikaze = {
    name = "kamikaze",
    verts = {0, -12, 8, -4, 12, 4, 8, 10, 0, 14, -8, 10, -12, 4, -8, -4},
    color = {1, 0.1, 0.5},
    hp = 1,
    radius = 12,
    speed = {150, 220},
    points = 15,
    xp = 8,
    credits = 4,
    shootChance = 0,
    behavior = "kamikaze",
    diveSpeed = 280,
    sineAmp = {0, 10},
    sineFreq = {3, 6},
    minWave = 4,
    weight = 6,
  },
  heavy = {
    name = "heavy",
    verts = {0, -22, 8, -12, 20, 0, 8, 12, 0, 22, -8, 12, -20, 0, -8, -12},
    color = {0.8, 0.4, 0.1},
    hp = 5,
    radius = 22,
    speed = {35, 65},
    points = 40,
    xp = 25,
    credits = 12,
    shootChance = 0.3,
    behavior = "tank",
    shootPattern = "spread",
    bulletCount = 3,
    sineAmp = {0, 10},
    sineFreq = {0.3, 0.8},
    minWave = 8,
    weight = 3,
  },
  bomber = {
    name = "bomber",
    verts = {0, -20, 12, -10, 18, 0, 12, 10, 0, 20, -12, 10, -18, 0, -12, -10},
    color = {0.9, 0.1, 0.5},
    hp = 3,
    radius = 18,
    speed = {50, 90},
    points = 35,
    xp = 18,
    credits = 9,
    shootChance = 0.5,
    behavior = "bomber",
    shootPattern = "rain",
    bulletCount = 5,
    sineAmp = {15, 35},
    sineFreq = {0.6, 1.2},
    minWave = 10,
    weight = 4,
  },
  dasher = {
    name = "dasher",
    verts = {0, -18, 14, -6, 14, 6, 0, 18, -14, 6, -14, -6},
    color = {0.3, 0.7, 1},
    hp = 2,
    radius = 14,
    speed = {100, 160},
    points = 22,
    xp = 11,
    credits = 5,
    shootChance = 0.2,
    behavior = "dash",
    dashSpeed = 350,
    dashCooldown = {1.5, 3},
    sineAmp = {0, 20},
    sineFreq = {1, 3},
    minWave = 6,
    weight = 5,
  },
  shielder = {
    name = "shielder",
    verts = {0, -20, 16, -8, 16, 8, 0, 20, -16, 8, -16, -8},
    color = {0.3, 0.5, 1},
    hp = 3,
    radius = 18,
    speed = {50, 85},
    points = 30,
    xp = 15,
    credits = 7,
    shootChance = 0.25,
    behavior = "shield",
    shieldHp = 2,
    shieldRadius = 24,
    sineAmp = {5, 15},
    sineFreq = {0.5, 1},
    minWave = 9,
    weight = 4,
  },
}

function EnemyTypes.getForWave(wave)
  local available = {}
  local totalWeight = 0
  for name, def in pairs(EnemyTypes.DEF) do
    if wave >= def.minWave then
      available[#available + 1] = {name = name, def = def, weight = def.weight}
      totalWeight = totalWeight + def.weight
    end
  end
  return available, totalWeight
end

function EnemyTypes.pick(available, totalWeight)
  local roll = math.random() * totalWeight
  local acc = 0
  for i = 1, #available do
    acc = acc + available[i].weight
    if roll <= acc then
      return available[i].def
    end
  end
  return available[#available].def
end

function EnemyTypes.getScaling(wave)
  local hpMul = 1 + (wave - 1) * 0.06
  local dmgMul = 1 + (wave - 1) * 0.04
  local spdMul = 1 + (wave - 1) * 0.02
  local countAdd = floor((wave - 1) / 3)
  return hpMul, dmgMul, spdMul, countAdd
end

return EnemyTypes
