-- powerup.lua
-- Entidad powerup: pickup temporal que otorga bonus al jugador.
-- Tipos: double_shot, speed, magnet, shield, heal.
-- Dura un tiempo limitado (duration) y parpadea antes de expirar.
-- Se recoge por proximidad (magnet range o contacto directo).

local Object = require("lib.classic")
local lume = require("lib.lume")

local Screen = require("src.graphics.screen")
local sin = math.sin
local lg = love.graphics
local lh = Screen.getHeight
local lgGetFont = lg.getFont

local Powerup = Object:extend()

local powerupTypes = {
  {
    name = "shield",
    color = {0.2, 0.6, 1},
    icon = "S",
    duration = 8,
    desc = "Shield",
  },
  {
    name = "double_shot",
    color = {1, 0.8, 0.2},
    icon = "D",
    duration = 10,
    desc = "Double Shot",
  },
  {
    name = "speed",
    color = {0.2, 1, 0.4},
    icon = "V",
    duration = 6,
    desc = "Speed",
  },
  {
    name = "heal",
    color = {1, 0.3, 0.5},
    icon = "+",
    duration = 0,
    desc = "Extra Life",
  },
  {
    name = "magnet",
    color = {0.8, 0.3, 1},
    icon = "M",
    duration = 8,
    desc = "Point Magnet",
  },
}

function Powerup:new(x, y)
  local t = lume.randomchoice(powerupTypes)
  self.x = x
  self.y = y
  self.type = t.name
  self.color = t.color
  self.icon = t.icon
  self.duration = t.duration
  self.desc = t.desc
  self.radius = 14
  self.speed = 60
  self.alive = true
  self.t = 0
  end

function Powerup:update(dt)
  self.t = self.t + dt
  self.y = self.y + self.speed * dt
  if self.y > lh() + 30 then
    self.alive = false
  end
end

function Powerup:draw()
  local pulse = sin(self.t * 4) * 0.15 + 0.85
  local r, g, b = self.color[1], self.color[2], self.color[3]
  local px, py = self.x, self.y

  lg.setColor(r, g, b, 0.15)
  lg.circle("fill", px, py, self.radius + 10)

  lg.setColor(r, g, b, 0.3 * pulse)
  lg.circle("fill", px, py, self.radius + 4)

  lg.setColor(r, g, b, 0.8)
  lg.circle("fill", px, py, self.radius)

  lg.setColor(1, 1, 1, 0.9)
  lg.setLineWidth(2)
  lg.circle("line", px, py, self.radius)

  lg.setColor(1, 1, 1, 1)
  local font = lgGetFont()
  local fw = font:getWidth(self.icon)
  lg.print(self.icon, px - fw / 2, py - 7)
end

function Powerup.getRandomSpawnChance()
  return 0.08
end

return Powerup
