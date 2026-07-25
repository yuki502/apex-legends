local WaveManager = {}
local floor = math.floor

local BASE_ENEMIES = 5
local ENEMIES_PER_WAVE = 2
local WAVE_DELAY = 2.0
local SHOP_DELAY = 0.5
local COUNTDOWN_TIME = 3.0

function WaveManager.update(g, dt)
  if g.state ~= "playing" or g.paused then return end

  if g.waveCountdown and g.waveCountdown > 0 then
    g.waveCountdown = g.waveCountdown - dt
    if g.waveCountdown <= 0 then
      g.waveCountdown = nil
      WaveManager.startWave(g)
    end
    return
  end

  if not g.waveActive then
    g.waveDelay = g.waveDelay - dt
    if g.waveDelay <= 0 then
      -- Boss waves go to shop after boss defeat
      if g.wave > 0 and g.wave % 10 == 0 then
        -- between-wave shop: components + upgrades
        g:enterShop()
        return
      end
      -- every 5 waves (non-boss), visit hangar
      if g.wave > 0 and g.wave % 5 == 0 then
        g:enterHangar()
        return
      end
      g.waveCountdown = COUNTDOWN_TIME
    end
  end
end

function WaveManager.startWave(g)
  g.wave = g.wave + 1
  g.bossWave = (g.wave % 10 == 0)

  local isSuperBoss = g.wave > 0 and g.wave % 1000 == 0
  local isBoss = g.wave > 0 and g.wave % 10 == 0

  g.waveActive = true
  g.enemiesSpawned = 0
  g.spawnTimer = 0

  if isSuperBoss then
    local SuperBossManager = require("src.managers.super_boss_manager")
    SuperBossManager.spawn(g, g.wave)
    g.enemiesInWave = 1
    g.bossWave = true
    g.spawnRate = 999
  elseif isBoss then
    local BossManager = require("src.managers.boss_manager")
    BossManager.spawn(g, g.wave)
    g.enemiesInWave = 1
    g.bossWave = true
    g.spawnRate = 999
  else
    local hpMul, dmgMul, spdMul, countAdd = (require("src.data.enemy_types")).getScaling(g.wave)
    g.enemiesInWave = floor(BASE_ENEMIES + g.wave * ENEMIES_PER_WAVE + countAdd)
    g.spawnRate = math.max(0.3, 1.1 - g.wave * 0.03)
  end

  if g.effects then
    g.effects:waveAnnounce(g.wave, g.bossWave)
  end
end

function WaveManager.checkWaveComplete(g)
  if g.bossWave then
    if g.bossWave and not g.boss and g.enemiesSpawned >= g.enemiesInWave and g.enemyCount == 0 then
      g.waveActive = false
      g.waveDelay = WAVE_DELAY
    end
    return
  end
  if g.waveActive and g.enemiesSpawned >= g.enemiesInWave and g.enemyCount == 0 then
    g.waveActive = false
    g.waveDelay = WAVE_DELAY
  end
end

function WaveManager.onBossDefeated(g)
  g.boss = nil
  g.waveActive = false
  g.waveDelay = WAVE_DELAY
  -- Boss drop: guaranteed rare+ component
  if g.inventory then
    local slots = {"weapon", "thruster", "core", "engine", "wing", "shield", "armor", "multiplier"}
    local slot = slots[love.math.random(1, #slots)]
    local comp = require("src.data.component_defs").getRandomBySlot(slot, g.wave + 5)
    if comp then
      g.inventory:add(comp.id)
      if g.effects then
        g.effects:installComponent(g.player and g.player.x or 350, g.player and g.player.y or 200, comp.rarityColor)
      end
    end
  end
end

return WaveManager
