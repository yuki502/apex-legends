local lg = love.graphics
local lw = lg.getWidth
local lh = lg.getHeight
local cos = math.cos
local sin = math.sin
local floor = math.floor
local random = math.random

local Shaders = require("src.shaders")

local SolarSystem = {}

-- ============================================================
-- SEEDED RNG (mulberry32)
-- ============================================================
local function createRNG(seed)
  local s = seed or 0
  return function()
    s = s + 0x6D2B79F5
    local t = s
    t = bit.bxor(t, bit.rshift(t, 15))
    t = bit.band(t * (t * t * 15731 + 789221), 0x7FFFFFFF)
    return t / 0x7FFFFFFF
  end
end

-- ============================================================
-- COLOR TABLES
-- ============================================================
local STAR_COLORS = {
  {1.0, 0.45, 0.2},   -- red M-class
  {1.0, 0.65, 0.25},  -- orange K-class
  {1.0, 0.95, 0.5},   -- yellow G-class
  {1.0, 1.0, 1.0},    -- white A-class
  {0.75, 0.85, 1.0},  -- blue-white B-class
}

local PLANET_PALETTES = {
  rocky = {
    color1 = {0.50, 0.48, 0.45}, color2 = {0.35, 0.33, 0.30},
  },
  mars = {
    color1 = {0.80, 0.35, 0.15}, color2 = {0.60, 0.25, 0.10},
  },
  earth = {
    color1 = {0.20, 0.45, 0.80}, color2 = {0.25, 0.60, 0.30},
  },
  ocean = {
    color1 = {0.10, 0.30, 0.70}, color2 = {0.15, 0.45, 0.85},
  },
  desert = {
    color1 = {0.85, 0.70, 0.40}, color2 = {0.70, 0.50, 0.25},
  },
  gasGiant = {
    color1 = {0.80, 0.60, 0.35}, color2 = {0.55, 0.35, 0.20},
  },
  gasBlue = {
    color1 = {0.35, 0.55, 0.85}, color2 = {0.25, 0.40, 0.70},
  },
  ice = {
    color1 = {0.75, 0.85, 0.95}, color2 = {0.55, 0.70, 0.85},
  },
  toxic = {
    color1 = {0.55, 0.75, 0.30}, color2 = {0.35, 0.55, 0.20},
  },
}

local PLANET_TYPES = {
  {type = 0, palette = "rocky",   atmo = false, rings = false},
  {type = 0, palette = "mars",    atmo = false, rings = false},
  {type = 0, palette = "earth",   atmo = true,  rings = false},
  {type = 0, palette = "ocean",   atmo = true,  rings = false},
  {type = 0, palette = "desert",  atmo = false, rings = false},
  {type = 1, palette = "gasGiant",atmo = true,  rings = true},
  {type = 1, palette = "gasBlue", atmo = true,  rings = false},
  {type = 2, palette = "ice",     atmo = false, rings = false},
  {type = 3, palette = "toxic",   atmo = true,  rings = false},
}

local RING_COLORS = {
  {0.75, 0.65, 0.50},
  {0.65, 0.60, 0.50},
  {0.80, 0.70, 0.55},
}

-- ============================================================
-- GENERATION
-- ============================================================
local function generateSystem(seed, layer)
  local rng = createRNG(seed)
  local sys = {}

  sys.seed = seed
  sys.layer = layer
  sys.alive = true

  -- Sun
  local colorIdx = floor(rng() * #STAR_COLORS) + 1
  local baseRadius = layer == 3 and (6 + rng() * 10) or (3 + rng() * 6)
  sys.sun = {
    radius = baseRadius,
    color = STAR_COLORS[colorIdx],
    intensity = 0.6 + rng() * 0.5,
  }

  -- Planets
  local planetCount = floor(rng() * 5) + 2
  sys.planets = {}
  local usedPalettes = {}
  local orbitDist = baseRadius * 2.5

  for i = 1, planetCount do
    local pType
    repeat
      pType = PLANET_TYPES[floor(rng() * #PLANET_TYPES) + 1]
    until not usedPalettes[pType.palette] or rng() > 0.6
    usedPalettes[pType.palette] = true

    local palette = PLANET_PALETTES[pType.palette]
    local pRadius = baseRadius * (0.2 + rng() * 0.45)
    orbitDist = orbitDist + pRadius * 2 + 4 + rng() * 12

    sys.planets[i] = {
      radius = pRadius,
      distance = orbitDist,
      angle = rng() * 6.28,
      speed = (0.15 + rng() * 0.35) / (orbitDist * 0.15),
      color1 = palette.color1,
      color2 = palette.color2,
      type = pType.type,
      hasAtmosphere = pType.atmo,
      hasRings = pType.rings and rng() > 0.3,
      ringColor = RING_COLORS[floor(rng() * #RING_COLORS) + 1],
      seed = floor(rng() * 10000),
    }
    orbitDist = orbitDist + pRadius
  end

  sys.width = orbitDist * 2 + 40
  sys.height = (baseRadius * 2) + 40

  return sys
end

-- ============================================================
-- OBJECT POOL
-- ============================================================
local _pool = {}
local _poolCount = 0

function SolarSystem.acquire(seed, layer)
  local sys
  if _poolCount > 0 then
    sys = _pool[_poolCount]
    _pool[_poolCount] = nil
    _poolCount = _poolCount - 1
    -- Regenerate with new seed
    local newSys = generateSystem(seed, layer)
    for k, v in pairs(newSys) do
      sys[k] = v
    end
  else
    sys = generateSystem(seed, layer)
  end
  return sys
end

function SolarSystem.release(sys)
  sys.alive = false
  _poolCount = _poolCount + 1
  _pool[_poolCount] = sys
end

function SolarSystem.getPoolSize()
  return _poolCount
end

-- ============================================================
-- UPDATE
-- ============================================================
function SolarSystem.update(sys, dt)
  for i = 1, #sys.planets do
    local p = sys.planets[i]
    p.angle = p.angle + p.speed * dt
    if p.angle > 6.2832 then
      p.angle = p.angle - 6.2832
    end
  end
end

-- ============================================================
-- DRAW
-- ============================================================
function SolarSystem.draw(sys, screenX, screenY, parallaxOffsetX, parallaxOffsetY, time)
  local wx = sys.x + parallaxOffsetX
  local wy = sys.y + parallaxOffsetY

  local w, h = lw(), lh()
  local margin = sys.width * 0.5 + 40
  if wx < -margin or wx > w + margin then return end
  if wy < -margin or wy > h + margin then return end

  -- Draw sun
  Shaders.drawSun(wx, wy, sys.sun.radius, sys.sun.color, sys.sun.intensity, time, sys.seed)

  -- Draw planets
  for i = 1, #sys.planets do
    local p = sys.planets[i]
    local px = wx + cos(p.angle) * p.distance
    local py = wy + sin(p.angle) * p.distance * 0.3

    if px > -20 and px < w + 20 and py > -20 and py < h + 20 then
      if p.hasRings then
        Shaders.drawRing(px, py, p.radius * 1.4, p.radius * 2.2, p.ringColor, p.seed)
      end
      Shaders.drawPlanet(px, py, p.radius, p.color1, p.color2, p.type, p.hasAtmosphere, time, p.seed)
    end
  end
end

return SolarSystem
