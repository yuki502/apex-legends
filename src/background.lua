local lg = love.graphics
local lw = lg.getWidth
local lh = lg.getHeight
local floor = math.floor
local random = math.random

local Shaders = require("src.shaders")
local SolarSystem = require("src.solar_system")

local Background = {}

-- ============================================================
-- LAYER CONFIGURATION
-- ============================================================
local LAYERS = {
  [1] = {speed = 1.0,  starCount = 60,  starMinSize = 1.8, starMaxSize = 3.2, starAlpha = 0.9,  hasSystems = false},
  [2] = {speed = 0.6,  starCount = 80,  starMinSize = 1.2, starMaxSize = 2.4, starAlpha = 0.7,  hasSystems = false},
  [3] = {speed = 0.3,  starCount = 50,  starMinSize = 0.8, starMaxSize = 1.6, starAlpha = 0.5,  hasSystems = true,  systemChance = 0.012},
  [4] = {speed = 0.12, starCount = 40,  starMinSize = 0.5, starMaxSize = 1.0, starAlpha = 0.35, hasSystems = true,  systemChance = 0.022},
}

local STAR_LAYER_COLORS = {
  {1.0, 0.95, 0.9},  -- warm white (close)
  {0.9, 0.92, 1.0},  -- neutral white
  {0.85, 0.88, 1.0}, -- cool white
  {0.8, 0.85, 1.0},  -- blue-ish (distant)
}

-- ============================================================
-- STATE
-- ============================================================
local _layers = {}
local _time = 0
local _seed = 42
local _initialized = false
local _scrollY = 0

-- ============================================================
-- SEEDED RNG
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
-- INITIALIZATION
-- ============================================================
function Background.init(seed)
  _seed = seed or 42
  _time = 0
  _scrollY = 0
  _layers = {}

  Shaders.init()

  for layerIdx = 1, 4 do
    local cfg = LAYERS[layerIdx]
    local layer = {
      stars = {},
      systems = {},
      speed = cfg.speed,
      cfg = cfg,
    }

    local rng = createRNG(_seed + layerIdx * 1000)
    local w, h = 800, 500

    for i = 1, cfg.starCount do
      layer.stars[i] = {
        x = rng() * w,
        y = rng() * h * 2,
        size = cfg.starMinSize + rng() * (cfg.starMaxSize - cfg.starMinSize),
        alpha = 0.4 + rng() * 0.6,
        twinkleSpeed = 1 + rng() * 3,
        twinklePhase = rng() * 6.28,
      }
    end

    if cfg.hasSystems then
      local sysCount = floor(cfg.systemChance * w * 0.5) + 1
      for i = 1, sysCount do
        local sysSeed = floor(rng() * 999999) + 1
        local sys = SolarSystem.acquire(sysSeed, layerIdx)
        sys.x = rng() * w
        sys.y = rng() * h * 2
        sys.alive = true
        layer.systems[i] = sys
      end
    end

    _layers[layerIdx] = layer
  end

  _initialized = true
end

-- ============================================================
-- UPDATE
-- ============================================================
function Background.update(dt, scrollDelta)
  if not _initialized then return end
  _time = _time + dt
  _scrollY = _scrollY + (scrollDelta or 0)

  for layerIdx = 1, 4 do
    local layer = _layers[layerIdx]
    local w, h = lw(), lh()
    local speed = layer.speed
    local scrollAmount = _scrollY * speed

    for i = 1, #layer.systems do
      local sys = layer.systems[i]
      SolarSystem.update(sys, dt)

      local viewY = sys.y - scrollAmount
      while viewY > h + 100 do
        sys.y = sys.y - h * 2
        viewY = viewY - h * 2
      end
      while viewY < -100 do
        sys.y = sys.y + h * 2
        viewY = viewY + h * 2
      end
    end
  end
end

-- ============================================================
-- DRAW STARS
-- ============================================================
local function drawStarLayer(layer, layerIdx)
  local w, h = lw(), lh()
  local cfg = layer.cfg
  local scrollAmount = _scrollY * layer.speed
  local col = STAR_LAYER_COLORS[layerIdx]

  for i = 1, #layer.stars do
    local s = layer.stars[i]
    local sy = s.y - (scrollAmount % (h * 2))
    if sy < -10 then sy = sy + h * 2 end
    if sy > h + 10 then sy = sy - h * 2 end

    local twinkle = math.sin(_time * s.twinkleSpeed + s.twinklePhase) * 0.3 + 0.7
    local a = cfg.starAlpha * s.alpha * twinkle

    lg.setColor(col[1], col[2], col[3], a)
    lg.circle("fill", s.x, sy, s.size)

    if s.size > 2.5 then
      lg.setColor(col[1], col[2], col[3], a * 0.3)
      lg.circle("fill", s.x, sy, s.size + 1.5)
    end
  end
end

-- ============================================================
-- DRAW SOLAR SYSTEMS
-- ============================================================
local function drawSystemLayer(layer, layerIdx)
  local w, h = lw(), lh()
  local scrollAmount = _scrollY * layer.speed

  for i = 1, #layer.systems do
    local sys = layer.systems[i]
    if sys.alive then
      sys.drawY = sys.y - scrollAmount
      SolarSystem.draw(sys, sys.x, sys.drawY, 0, 0, _time)
    end
  end
end

-- ============================================================
-- DRAW (called from game)
-- ============================================================
function Background.draw()
  if not _initialized then return end

  for layerIdx = 1, 4 do
    local layer = _layers[layerIdx]
    drawStarLayer(layer, layerIdx)
  end

  for layerIdx = 3, 4 do
    drawSystemLayer(_layers[layerIdx], layerIdx)
  end
end

-- ============================================================
-- RESET
-- ============================================================
function Background.reset(seed)
  Background.init(seed or _seed)
end

function Background.getSeed()
  return _seed
end

return Background
