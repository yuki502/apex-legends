-- menus.lua
-- Menú principal y pantallas de estado (game over, pausa).
-- Starfield pre-generado con 3 capas para animación de fondo.
-- Renderiza: título, high score, botón de inicio, versión.
-- Incluye animación de fade-out al iniciar partida.

local sin = math.sin
local cos = math.cos
local Screen = require("src.graphics.screen")
local lg = love.graphics
local lw = Screen.getWidth
local lh = Screen.getHeight

local Menus = {}

-- Starfield (pre-generated, 3 layers)
local _stars = nil
local _starLayers = {0.3, 0.6, 1.0}
local _starSpeeds = {15, 35, 60}
local _starSizes = {1.5, 2, 2.8}
local _starAlphas = {0.25, 0.4, 0.7}
local _starsPerLayer = 30

local function initStars()
  if _stars then return end
  _stars = {}
  for layer = 1, 3 do
    for i = 1, _starsPerLayer do
      local idx = #_stars + 1
      _stars[idx] = {
        x = math.random() * lw(),
        y = math.random() * lh(),
        layer = layer,
      }
    end
  end
end

function Menus.updateStars(dt)
  initStars()
  for i = 1, #_stars do
    local s = _stars[i]
    s.y = s.y + _starSpeeds[s.layer] * dt
    if s.y > lh() + 10 then
      s.y = -5
      s.x = math.random() * lw()
    end
  end
end

local function drawStarfield(alpha)
  if not _stars then return end
  for i = 1, #_stars do
    local s = _stars[i]
    local a = _starAlphas[s.layer] * alpha
    lg.setColor(0.8, 0.9, 1, a)
    lg.circle("fill", s.x, s.y, _starSizes[s.layer])
  end
end

-- Fade helper: returns 0..1 based on time and delay
local function fadeIn(t, delay, duration)
  local v = (t - delay) / duration
  if v < 0 then return 0 end
  if v > 1 then return 1 end
  return v
end

-- Smooth step
local function smoothstep(v)
  v = v < 0 and 0 or (v > 1 and 1 or v)
  return v * v * (3 - 2 * v)
end

function Menus.drawMenu(g)
  local w, h = lw(), lh()
  local t = g.menuTimer

  -- Background: dark gradient
  lg.setColor(0.02, 0.03, 0.06, 1)
  lg.rectangle("fill", 0, 0, w, h)

  -- Fade in control
  local masterAlpha = fadeIn(t, 0, 1.2)
  local starAlpha = fadeIn(t, 0, 0.8)

  -- Starfield background
  Menus.updateStars(1 / 60)
  drawStarfield(starAlpha * masterAlpha)

  -- Subtle nebula glow
  local nebulaAlpha = masterAlpha * 0.04
  lg.setColor(0.15, 0.3, 0.6, nebulaAlpha)
  lg.circle("fill", w * 0.3, h * 0.4, 120)
  lg.setColor(0.4, 0.15, 0.5, nebulaAlpha * 0.7)
  lg.circle("fill", w * 0.7, h * 0.5, 90)

  -- Title animation: fade + slide
  local titleDelay = 0.2
  local titleAlpha = smoothstep(fadeIn(t, titleDelay, 0.8))
  local titleSlide = (1 - titleAlpha) * -30

  lg.setFont(g.bigFont)
  local title = "APEX LEGENDS"
  local tw = g.bigFont:getWidth(title)
  local titleY = h * 0.14 + titleSlide

  -- Title glow
  local glowPulse = sin(t * 2) * 0.1 + 0.9
  lg.setColor(0.3, 0.7, 1, titleAlpha * 0.12 * glowPulse)
  lg.print(title, w / 2 - tw / 2 + 1, titleY + 2)

  -- Title shadow
  lg.setColor(0.05, 0.1, 0.25, titleAlpha * 0.5)
  lg.print(title, w / 2 - tw / 2 + 1, titleY + 1)

  -- Title main
  lg.setColor(0.3, 0.85, 1, titleAlpha)
  lg.print(title, w / 2 - tw / 2, titleY)

  -- Decorative line under title
  local lineDelay = 0.5
  local lineAlpha = smoothstep(fadeIn(t, lineDelay, 0.6))
  local lineW = 140 * lineAlpha
  local lineY = titleY + 46
  lg.setColor(0.3, 0.7, 1, lineAlpha * 0.3)
  lg.setLineWidth(1)
  lg.line(w / 2 - lineW, lineY, w / 2 + lineW, lineY)
  lg.setColor(0.3, 0.8, 1, lineAlpha * 0.6)
  lg.circle("fill", w / 2 - lineW, lineY, 2)
  lg.circle("fill", w / 2 + lineW, lineY, 2)

  -- Subtitle animation
  local subDelay = 0.6
  local subAlpha = smoothstep(fadeIn(t, subDelay, 0.7))
  local subSlide = (1 - subAlpha) * -15

  lg.setFont(g.titleFont)
  local sub = "SPACE SHOOTER"
  local sw = g.titleFont:getWidth(sub)
  local subY = titleY + 54 + subSlide

  lg.setColor(0.6, 0.85, 1, subAlpha * 0.4)
  lg.print(sub, w / 2 - sw / 2 + 1, subY + 1)
  lg.setColor(1, 1, 1, subAlpha * 0.6)
  lg.print(sub, w / 2 - sw / 2, subY)

  -- Ship with enhanced animation
  local shipDelay = 0.9
  local shipAlpha = smoothstep(fadeIn(t, shipDelay, 0.8))
  local shipX = w / 2
  local shipY = h * 0.48
  local bob = sin(t * 1.8) * 8
  local sway = cos(t * 1.2) * 4
  local tilt = cos(t * 1.5) * 0.06
  shipY = shipY + bob
  shipX = shipX + sway

  if shipAlpha > 0 then
    -- Ship glow (soft halo)
    local glowSize = 32 + sin(t * 3) * 4
    lg.setColor(0.2, 0.5, 1, shipAlpha * 0.08)
    lg.circle("fill", shipX, shipY, glowSize)
    lg.setColor(0.3, 0.6, 1, shipAlpha * 0.05)
    lg.circle("fill", shipX, shipY, glowSize + 10)

    -- Engine glow (behind ship)
    local engineFlare = sin(t * 8) * 2
    lg.setColor(0.3, 0.6, 1, shipAlpha * 0.15)
    lg.circle("fill", shipX, shipY + 22, 10 + engineFlare)
    lg.setColor(1, 0.5, 0.2, shipAlpha * 0.2)
    lg.circle("fill", shipX, shipY + 25, 6 + engineFlare * 0.5)

    -- Ship body
    local c = cos(tilt)
    local s = sin(tilt)
    local verts = {0, -22, 14, 10, 10, 20, -10, 20, -14, 10}
    local drawV = {}
    for i = 1, #verts, 2 do
      local vx, vy = verts[i], verts[i + 1]
      drawV[#drawV + 1] = shipX + vx * c - vy * s
      drawV[#drawV + 1] = shipY + vx * s + vy * c
    end

    lg.setColor(0.12, 0.35, 0.6, shipAlpha * 0.7)
    lg.polygon("fill", drawV)
    lg.setColor(0.3, 0.75, 1, shipAlpha * 0.9)
    lg.setLineWidth(2)
    lg.polygon("line", drawV)

    -- Cockpit
    lg.setColor(0.5, 0.9, 1, shipAlpha * 0.7)
    lg.circle("fill", shipX + 2, shipY - 10, 4)
    lg.setColor(0.6, 0.95, 1, shipAlpha * 0.3)
    lg.circle("fill", shipX + 2, shipY - 10, 7)
  end

  -- High score
  if g.highScore > 0 then
    local hsDelay = 1.3
    local hsAlpha = smoothstep(fadeIn(t, hsDelay, 0.6))
    lg.setFont(g.smallFont)
    lg.setColor(1, 0.8, 0.2, hsAlpha * 0.8)
    local hs = "RECORD: " .. g.highScore
    lg.print(hs, w / 2 - g.smallFont:getWidth(hs) / 2, shipY + 50)
  end

  -- START button with pulsing border
  local btnDelay = 1.0
  local btnAlpha = smoothstep(fadeIn(t, btnDelay, 0.8))
  local btnW, btnH = 180, 48
  local btnX = w / 2 - btnW / 2
  local btnY = h * 0.78
  local pulse = 0.7 + sin(t * 3) * 0.3

  -- Button outer glow
  lg.setColor(0.15, 0.6, 0.35, btnAlpha * pulse * 0.15)
  lg.rectangle("fill", btnX - 8, btnY - 8, btnW + 16, btnH + 16, 14, 14)

  -- Button border
  lg.setColor(0.2, 0.7, 0.4, btnAlpha * pulse * 0.4)
  lg.setLineWidth(1.5)
  lg.rectangle("line", btnX - 2, btnY - 2, btnW + 4, btnH + 4, 12, 12)

  -- Button fill
  lg.setColor(0.12, 0.35, 0.2, btnAlpha * 0.6)
  lg.rectangle("fill", btnX, btnY, btnW, btnH, 10, 10)
  lg.setColor(0.15, 0.5, 0.3, btnAlpha * pulse * 0.8)
  lg.rectangle("fill", btnX, btnY, btnW, btnH, 10, 10)

  -- Button text
  lg.setColor(1, 1, 1, btnAlpha * 0.95)
  lg.setFont(g.font)
  lg.print("START", w / 2 - g.font:getWidth("START") / 2, btnY + 13)

  -- "Tap to Start" blinking
  local tapDelay = 1.4
  local tapAlpha = smoothstep(fadeIn(t, tapDelay, 0.5))
  if tapAlpha > 0 then
    local blink = sin(t * 4) * 0.5 + 0.5
    lg.setFont(g.smallFont)
    lg.setColor(0.6, 0.8, 1, tapAlpha * blink * 0.6)
    local tapText = "Tap to Start"
    lg.print(tapText, w / 2 - g.smallFont:getWidth(tapText) / 2, btnY + btnH + 14)
  end

  -- Version
  lg.setFont(g.tinyFont)
  lg.setColor(1, 1, 1, masterAlpha * 0.2)
  lg.print("v3.0", w / 2 - g.tinyFont:getWidth("v3.0") / 2, h - 14)
end

-- Fade out overlay (drawn on top during transition)
function Menus.drawFadeOut(g, alpha)
  if alpha <= 0 then return end
  lg.setColor(0, 0, 0, alpha)
  lg.rectangle("fill", 0, 0, lw(), lh())
end

return Menus
