local CurrencyManager = {}

local _coins = 0
local _totalEarned = 0

function CurrencyManager.init()
  _coins = 0
  _totalEarned = 0
  local ok, data = pcall(love.filesystem.read, "currency.dat")
  if ok and data then
    _coins = tonumber(data) or 0
  end
end

function CurrencyManager.save()
  pcall(love.filesystem.write, "currency.dat", tostring(_coins))
end

function CurrencyManager.get()
  return _coins
end

function CurrencyManager.getTotal()
  return _totalEarned
end

function CurrencyManager.add(amount)
  _coins = _coins + amount
  _totalEarned = _totalEarned + amount
end

function CurrencyManager.spend(amount)
  if _coins >= amount then
    _coins = _coins - amount
    CurrencyManager.save()
    return true
  end
  return false
end

function CurrencyManager.canAfford(amount)
  return _coins >= amount
end

function CurrencyManager.getEnemyReward(wave)
  local base = 1 + math.floor(wave * 0.15)
  return base
end

function CurrencyManager.getBossReward(wave)
  local base = 20 + wave * 5
  return base
end

function CurrencyManager.getSuperBossReward(wave)
  local base = 100 + wave * 15
  return base
end

return CurrencyManager
