-- ship_designs.lua
-- Diseños visuales de naves disponibles para el jugador.
-- Cada diseño tiene: nombre, vértices, color, accent.
-- Los vértices definen la forma de la nave al renderizar.
-- Se muestran en la pantalla de selección (customize).

local lume = require("lib.lume")

local ShipDesigns = {}

-- Lista de diseños disponibles
ShipDesigns.list = {
  {
    name = "FALCON",
    verts = {0, -22, 14, 10, 10, 20, -10, 20, -14, 10},
    color = {0.3, 0.8, 1},
    accent = {0.5, 0.9, 1},
    engineColor = {1, 0.5, 0.1},
    radius = 18,
    desc = "Balanced classic",
  },
  {
    name = "VIPER",
    verts = {0, -26, 8, -8, 18, 12, 6, 22, -6, 22, -18, 12, -8, -8},
    color = {0.2, 1, 0.4},
    accent = {0.4, 1, 0.6},
    engineColor = {0.2, 1, 0.4},
    radius = 20,
    desc = "Fast and deadly",
  },
  {
    name = "PHANTOM",
    verts = {0, -20, 20, 0, 12, 18, -12, 18, -20, 0},
    color = {0.7, 0.2, 1},
    accent = {0.9, 0.4, 1},
    engineColor = {0.7, 0.2, 1},
    radius = 19,
    desc = "Stealthy and powerful",
  },
  {
    name = "TITAN",
    verts = {0, -18, 22, 6, 18, 22, -18, 22, -22, 6},
    color = {1, 0.6, 0.1},
    accent = {1, 0.8, 0.3},
    engineColor = {1, 0.4, 0.1},
    radius = 22,
    desc = "Tough tank",
  },
  {
    name = "NOVA",
    verts = {0, -24, 6, -10, 16, 4, 10, 20, -10, 20, -16, 4, -6, -10},
    color = {1, 0.2, 0.4},
    accent = {1, 0.4, 0.6},
    engineColor = {1, 0.3, 0.5},
    radius = 19,
    desc = "Agile and precise",
  },
  {
    name = "GHOST",
    verts = {0, -20, 12, -4, 20, 10, 8, 22, -8, 22, -20, 10, -12, -4},
    color = {0.4, 0.6, 0.9},
    accent = {0.6, 0.8, 1},
    engineColor = {0.4, 0.6, 0.9},
    radius = 20,
    desc = "Interdimensional phantom",
  },
}

function ShipDesigns.get(index)
  index = index or 1
  index = lume.clamp(index, 1, #ShipDesigns.list)
  return ShipDesigns.list[index]
end

function ShipDesigns.count()
  return #ShipDesigns.list
end

return ShipDesigns
