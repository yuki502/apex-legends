local BossManager = {}

local BOSS_TYPES = {
  {
    name = "DESTROYER",
    color = {0.85, 0.15, 0.1},
    accent = {1, 0.3, 0.2},
    radiusBase = 38,
    hpBase = 25,
    speedBase = 35,
    shootRateBase = 1.0,
    scoreBase = 150,
    coinsBase = 30,
  },
  {
    name = "DEVASTATOR",
    color = {0.7, 0.1, 0.6},
    accent = {1, 0.2, 0.8},
    radiusBase = 42,
    hpBase = 35,
    speedBase = 30,
    shootRateBase = 0.9,
    scoreBase = 200,
    coinsBase = 40,
  },
  {
    name = "ANNIHILATOR",
    color = {0.1, 0.3, 0.9},
    accent = {0.3, 0.6, 1},
    radiusBase = 45,
    hpBase = 45,
    speedBase = 28,
    shootRateBase = 0.8,
    scoreBase = 250,
    coinsBase = 50,
  },
  {
    name = "OBLIVION",
    color = {0.9, 0.5, 0.1},
    accent = {1, 0.7, 0.2},
    radiusBase = 48,
    hpBase = 55,
    speedBase = 25,
    shootRateBase = 0.7,
    scoreBase = 300,
    coinsBase = 60,
  },
}

function BossManager.spawn(g, wave)
  local Boss = require("src.entities.boss")
  local idx = math.min(math.floor(wave / 10), #BOSS_TYPES)
  idx = math.max(1, idx)
  local template = BOSS_TYPES[idx]
  g.boss = Boss(wave, template)
  g.boss.name = template.name
end

function BossManager.getTemplate(wave)
  local idx = math.min(math.floor(wave / 10), #BOSS_TYPES)
  return BOSS_TYPES[math.max(1, idx)]
end

return BossManager
