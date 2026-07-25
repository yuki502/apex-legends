-- consumable_manager.lua
-- Gestión de consumibles: repair kit, bomb, shield, damage boost.
-- Se compran en la tienda y se usan durante el juego.
-- Cada consumible tiene: costo, stock máximo, y efecto al usar.
-- Persiste entre partidas via consumables.dat.

local ConsumableManager = {}

-- Definición de consumibles disponibles
local DEF = {
  repair = {
    name = "Repair Kit",
    desc = "Restore 2 lives instantly",
    icon = "FIX",
    color = {0.3, 1, 0.5},
    cost = 12,
    maxStock = 10,
    key = "1",
    use = function(g)
      g.player.lives = math.min(g.player.lives + 2, g.player.maxLives)
    end,
  },
  shield = {
    name = "Shield Cell",
    desc = "Gain 3 shield points",
    icon = "SHD",
    color = {0.3, 0.6, 1},
    cost = 15,
    maxStock = 8,
    key = "2",
    use = function(g)
      g.player.shield = math.min(g.player.shield + 3, g.player.maxShield)
    end,
  },
  damageBoost = {
    name = "Damage Amp",
    desc = "+100% damage for 8s",
    icon = "AMP",
    color = {1, 0.3, 0.2},
    cost = 20,
    maxStock = 5,
    key = "3",
    use = function(g)
      g.player.hasDamageBoost = true
      g.player.damageTimer = 8
    end,
  },
  freeze = {
    name = "Cryo Grenade",
    desc = "Freeze all enemies 4s",
    icon = "FRZ",
    color = {0.5, 0.8, 1},
    cost = 18,
    maxStock = 5,
    key = "4",
    use = function(g)
      for i = 1, g.enemyCount do
        local e = g.enemies[i]
        e.frozen = 4
      end
    end,
  },
  bomb = {
    name = "Nova Bomb",
    desc = "Destroy nearby enemies",
    icon = "NOV",
    color = {1, 0.8, 0.2},
    cost = 25,
    maxStock = 3,
    key = "5",
    use = function(g)
      local px, py = g.player.x, g.player.y
      local range = 150
      local i = 1
      while i <= g.enemyCount do
        local e = g.enemies[i]
        local dx = e.x - px
        local dy = e.y - py
        if dx * dx + dy * dy < range * range then
          e.hp = 0
          e.alive = false
          g.effects:explode(e.x, e.y, e.color, 12, 150)
          g:removeEnemy(i)
        else
          i = i + 1
        end
      end
      g.shake:trigger(8, 0.3)
    end,
  },
  speedBoost = {
    name = "Turbo Boost",
    desc = "+80% speed for 6s",
    icon = "TUR",
    color = {0.2, 0.8, 1},
    cost = 14,
    maxStock = 6,
    key = "6",
    use = function(g)
      g.player.hasSpeedItem = true
      g.player.speedTimer = 6
    end,
  },
  magnet = {
    name = "Coin Magnet",
    desc = "Pull coins 10s",
    icon = "MAG",
    color = {0.8, 0.3, 1},
    cost = 10,
    maxStock = 8,
    key = "7",
    use = function(g)
      g.player.hasMagnet = true
      g.player.magnetTimer = 10
    end,
  },
  invuln = {
    name = "Phase Shift",
    desc = "Invulnerable 5s",
    icon = "PHS",
    color = {0.5, 0.5, 1},
    cost = 30,
    maxStock = 3,
    key = "8",
    use = function(g)
      g.player.invincible = 5
    end,
  },
}

local _stock = {}

function ConsumableManager.init()
  _stock = {}
  for k in pairs(DEF) do
    _stock[k] = 0
  end
  local ok, data = pcall(love.filesystem.read, "consumables.dat")
  if ok and data then
    for line in data:gmatch("[^\n]+") do
      local k, v = line:match("^([^=]+)=(%d+)$")
      if k and v and DEF[k] then
        _stock[k] = tonumber(v)
      end
    end
  end
end

function ConsumableManager.save()
  local lines = {}
  for k, v in pairs(_stock) do
    lines[#lines + 1] = k .. "=" .. tostring(v)
  end
  pcall(love.filesystem.write, "consumables.dat", table.concat(lines, "\n"))
end

function ConsumableManager.getStock(key)
  return _stock[key] or 0
end

function ConsumableManager.buy(key)
  local def = DEF[key]
  if not def then return false end
  local stock = _stock[key] or 0
  if stock >= def.maxStock then return false end
  local CurrencyManager = require("src.managers.currency_manager")
  if not CurrencyManager.spend(def.cost) then return false end
  _stock[key] = stock + 1
  ConsumableManager.save()
  return true
end

function ConsumableManager.use(key, g)
  local def = DEF[key]
  if not def then return false end
  if (_stock[key] or 0) <= 0 then return false end
  _stock[key] = _stock[key] - 1
  def.use(g)
  ConsumableManager.save()
  return true
end

function ConsumableManager.canBuy(key)
  local def = DEF[key]
  if not def then return false end
  local stock = _stock[key] or 0
  if stock >= def.maxStock then return false end
  local CurrencyManager = require("src.managers.currency_manager")
  return CurrencyManager.canAfford(def.cost)
end

function ConsumableManager.getAll()
  local result = {}
  for k, def in pairs(DEF) do
    result[#result + 1] = {
      key = k,
      name = def.name,
      desc = def.desc,
      icon = def.icon,
      color = def.color,
      cost = def.cost,
      stock = _stock[k] or 0,
      maxStock = def.maxStock,
      hotkey = def.key,
    }
  end
  return result
end

function ConsumableManager.getActiveItems()
  local result = {}
  for k, def in pairs(DEF) do
    if (_stock[k] or 0) > 0 then
      result[#result + 1] = {
        key = k,
        name = def.name,
        icon = def.icon,
        color = def.color,
        stock = _stock[k],
        hotkey = def.key,
      }
    end
  end
  return result
end

return ConsumableManager
