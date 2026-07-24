local UpgradeManager = {}

local DEF = {
  damage = {
    name = "Damage",
    desc = "+15% bullet damage",
    icon = "DMG",
    color = {1, 0.3, 0.2},
    baseCost = 15,
    costScale = 1.4,
    maxLevel = 20,
    effect = function(level) return 1 + level * 0.15 end,
  },
  fireRate = {
    name = "Fire Rate",
    desc = "+12% shoot speed",
    icon = "ROF",
    color = {1, 0.8, 0.2},
    baseCost = 12,
    costScale = 1.35,
    maxLevel = 20,
    effect = function(level) return 1 + level * 0.12 end,
  },
  moveSpeed = {
    name = "Speed",
    desc = "+10% move speed",
    icon = "SPD",
    color = {0.2, 0.8, 1},
    baseCost = 10,
    costScale = 1.3,
    maxLevel = 15,
    effect = function(level) return 1 + level * 0.10 end,
  },
  maxHp = {
    name = "Hull",
    desc = "+1 max life",
    icon = "HP+",
    color = {0.2, 1, 0.4},
    baseCost = 20,
    costScale = 1.5,
    maxLevel = 10,
    effect = function(level) return level end,
  },
  heal = {
    name = "Repair",
    desc = "Restore 1 life",
    icon = "FIX",
    color = {0.3, 1, 0.5},
    baseCost = 8,
    costScale = 1.2,
    maxLevel = 999,
    consumable = true,
    effect = function(level) return 1 end,
  },
  critChance = {
    name = "Crit",
    desc = "+5% critical chance",
    icon = "CRT",
    color = {1, 0.1, 0.6},
    baseCost = 18,
    costScale = 1.45,
    maxLevel = 15,
    effect = function(level) return level * 0.05 end,
  },
  magnetRange = {
    name = "Magnet",
    desc = "+20% coin pickup range",
    icon = "MAG",
    color = {0.8, 0.3, 1},
    baseCost = 10,
    costScale = 1.25,
    maxLevel = 10,
    effect = function(level) return 1 + level * 0.20 end,
  },
  shield = {
    name = "Shield",
    desc = "+1 shield point",
    icon = "SHD",
    color = {0.3, 0.6, 1},
    baseCost = 25,
    costScale = 1.6,
    maxLevel = 5,
    effect = function(level) return level end,
  },
}

local _levels = {}

function UpgradeManager.init()
  _levels = {}
  for k in pairs(DEF) do
    _levels[k] = 0
  end
  local ok, data = pcall(love.filesystem.read, "upgrades.dat")
  if ok and data then
    for line in data:gmatch("[^\n]+") do
      local k, v = line:match("^([^=]+)=(%d+)$")
      if k and v and DEF[k] then
        _levels[k] = tonumber(v)
      end
    end
  end
end

function UpgradeManager.save()
  local lines = {}
  for k, v in pairs(_levels) do
    lines[#lines + 1] = k .. "=" .. tostring(v)
  end
  pcall(love.filesystem.write, "upgrades.dat", table.concat(lines, "\n"))
end

function UpgradeManager.getLevel(key)
  return _levels[key] or 0
end

function UpgradeManager.getEffect(key)
  local def = DEF[key]
  if not def then return 1 end
  return def.effect(_levels[key] or 0)
end

function UpgradeManager.getCost(key)
  local def = DEF[key]
  local level = _levels[key] or 0
  if def.consumable then
    return math.floor(def.baseCost * (def.costScale ^ level))
  end
  return math.floor(def.baseCost * (def.costScale ^ level))
end

function UpgradeManager.getMaxLevel(key)
  return DEF[key] and DEF[key].maxLevel or 0
end

function UpgradeManager.canBuy(key)
  local def = DEF[key]
  if not def then return false end
  local level = _levels[key] or 0
  if not def.consumable and level >= def.maxLevel then return false end
  return true
end

function UpgradeManager.purchase(key)
  local def = DEF[key]
  if not def then return false end
  if not UpgradeManager.canBuy(key) then return false end
  local cost = UpgradeManager.getCost(key)
  local CurrencyManager = require("src.currency_manager")
  if not CurrencyManager.spend(cost) then return false end
  if not def.consumable then
    _levels[key] = (_levels[key] or 0) + 1
  end
  UpgradeManager.save()
  return true, cost
end

function UpgradeManager.reset()
  _levels = {}
  for k in pairs(DEF) do
    _levels[k] = 0
  end
  UpgradeManager.save()
end

function UpgradeManager.getAll()
  local result = {}
  for k, def in pairs(DEF) do
    result[#result + 1] = {
      key = k,
      name = def.name,
      desc = def.desc,
      icon = def.icon,
      color = def.color,
      level = _levels[k] or 0,
      maxLevel = def.maxLevel,
      cost = UpgradeManager.getCost(k),
      canBuy = UpgradeManager.canBuy(k),
      consumable = def.consumable or false,
    }
  end
  return result
end

return UpgradeManager
