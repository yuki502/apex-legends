local SuperBossManager = {}

local SUPER_BOSS_DEFS = {
  {
    name = "COLOSSUS",
    phases = {
      {color = {0.9, 0.2, 0.1}, accent = {1, 0.4, 0.2}, radiusBase = 60, hpBase = 120, speedBase = 20, shootRateBase = 0.6},
      {color = {1.0, 0.5, 0.0}, accent = {1, 0.7, 0.1}, radiusBase = 65, hpBase = 100, speedBase = 25, shootRateBase = 0.45},
      {color = {1.0, 0.8, 0.0}, accent = {1, 1.0, 0.3}, radiusBase = 70, hpBase = 80, speedBase = 32, shootRateBase = 0.3},
    },
    scoreBase = 1000,
    coinsBase = 200,
  },
  {
    name = "VOID WALKER",
    phases = {
      {color = {0.3, 0.1, 0.8}, accent = {0.5, 0.3, 1}, radiusBase = 55, hpBase = 110, speedBase = 25, shootRateBase = 0.55},
      {color = {0.5, 0.0, 1.0}, accent = {0.7, 0.4, 1}, radiusBase = 60, hpBase = 90, speedBase = 30, shootRateBase = 0.4},
      {color = {0.8, 0.2, 1.0}, accent = {1.0, 0.5, 1}, radiusBase = 65, hpBase = 70, speedBase = 38, shootRateBase = 0.25},
    },
    scoreBase = 1200,
    coinsBase = 250,
  },
}

function SuperBossManager.spawn(g, wave)
  local Boss = require("src.boss")
  local cycle = math.floor((wave - 1) / 1000) % #SUPER_BOSS_DEFS
  local def = SUPER_BOSS_DEFS[cycle + 1]
  local phaseIdx = math.floor(((wave - 1) % 1000) / 100) + 1
  phaseIdx = math.min(phaseIdx, #def.phases)
  local phase = def.phases[phaseIdx]

  g.boss = Boss(wave, phase)
  g.boss.name = def.name .. " P" .. phaseIdx
  g.boss.isSuperBoss = true
  g.boss.superPhase = phaseIdx
  g.boss.superDef = def
  g.boss.superCoins = def.coinsBase + phaseIdx * 50
end

function SuperBossManager.onPhaseDefeated(g)
  local boss = g.boss
  if not boss or not boss.isSuperBoss then return false end

  local nextPhase = boss.superPhase + 1
  if nextPhase > #boss.superDef.phases then
    return false
  end

  local Boss = require("src.boss")
  local phase = boss.superDef.phases[nextPhase]
  local newBoss = Boss(boss.wave, phase)
  newBoss.name = boss.superDef.name .. " P" .. nextPhase
  newBoss.isSuperBoss = true
  newBoss.superPhase = nextPhase
  newBoss.superDef = boss.superDef
  newBoss.superCoins = boss.superDef.coinsBase + nextPhase * 50
  newBoss.entering = true
  newBoss.y = -60

  g.boss = newBoss
  return true
end

return SuperBossManager
