-- collision.lua
-- Sistema de detección de colisiones y respuesta.
-- Maneja: balas del jugador vs enemigos, balas enemigas vs jugador,
-- enemigos vs jugador, y recolección de powerups.
-- Optimizado: colisión inline (sin llamada a función), caching de referencias.
-- Cada función maneja su propia eliminación de entidades (swap-remove).

local sqrt = math.sqrt
local min = math.min
local lume = require("lib.lume")
local Audio = require("src.utils.audio")
local SpawnManager = require("src.managers.spawn_manager")
local State = require("src.systems.state")
local CurrencyManager = require("src.managers.currency_manager")
local UpgradeManager = require("src.managers.upgrade_manager")

local Collision = {}

-- ═══════════════════════════════════════════════════════
-- UTILIDADES DE COLISIÓN
-- ═══════════════════════════════════════════════════════

--- Calcula la distancia al cuadrado entre dos puntos.
-- Más rápido que dist() porque evita la raíz cuadrada.
function Collision.distSq(x1, y1, x2, y2)
  local dx = x1 - x2
  local dy = y1 - y2
  return dx * dx + dy * dy
end

--- Verifica colisión entre dos círculos.
function Collision.circle(x1, y1, r1, x2, y2, r2)
  local d = r1 + r2
  return Collision.distSq(x1, y1, x2, y2) < d * d
end

-- ═══════════════════════════════════════════════════════
-- ACTUALIZACIÓN PRINCIPAL
-- ═══════════════════════════════════════════════════════

--- Actualiza todos los sistemas de colisión.
-- Solo se ejecuta en estado "playing" y si no está pausado.
-- @param g Referencia al juego (Game)
-- @param dt Delta time
function Collision.updateAll(g, dt)
  if g.state ~= "playing" or g.paused then return end

  Collision.updateBullets(g, dt)
  Collision.updateEnemyBullets(g, dt)
  Collision.bulletsVsEnemies(g)
  Collision.bulletsVsBoss(g)
  Collision.enemiesVsPlayer(g)
  Collision.updatePowerups(g, dt)
  Collision.updateTimers(g, dt)
end

function Collision.distSq(x1, y1, x2, y2)
  local dx = x1 - x2
  local dy = y1 - y2
  return dx * dx + dy * dy
end

function Collision.circle(x1, y1, r1, x2, y2, r2)
  local d = r1 + r2
  return Collision.distSq(x1, y1, x2, y2) < d * d
end

function Collision.updateAll(g, dt)
  if g.state ~= "playing" or g.paused then return end

  Collision.updateBullets(g, dt)
  Collision.updateEnemyBullets(g, dt)
  Collision.bulletsVsEnemies(g)
  Collision.bulletsVsBoss(g)
  Collision.enemiesVsPlayer(g)
  Collision.updatePowerups(g, dt)
  Collision.updateTimers(g, dt)
end

--- Actualiza los timers de powerups del jugador (damage boost, speed, magnet).
-- Decrementa timers y desactiva powerups cuando expiran.
function Collision.updateTimers(g, dt)
  local player = g.player
  if not player then return end
  if player.hasDamageBoost then
    player.damageTimer = player.damageTimer - dt
    if player.damageTimer <= 0 then
      player.hasDamageBoost = false
    end
  end
  if player.hasSpeedItem then
    player.speedTimer = player.speedTimer - dt
    if player.speedTimer <= 0 then
      player.hasSpeedItem = false
    end
  end
  if player.magnetTimer then
    player.magnetTimer = player.magnetTimer - dt
    if player.magnetTimer <= 0 then
      player.hasMagnet = false
    end
  end
end

--- Actualiza las balas del jugador.
-- Mueve cada bala y la elimina si sale de pantalla o muere.
-- Optimizado: usa while-loop con swap-remove para evitar re-indexación.
function Collision.updateBullets(g, dt)
  local i = 1
  while i <= g.bulletCount do
    local b = g.bullets[i]
    if b and b.alive then
      local alive = b:update(dt, g.enemies)
      if not alive or not b.alive then
        g:removeBullet(i)
      else
        i = i + 1
      end
    else
      g:removeBullet(i)
    end
  end
end

--- Actualiza las balas enemigas y detecta colisión con el jugador.
-- Optimizado: caching de px/py/pr al inicio, colisión inline.
-- Si colisiona: elimina bala, aplica daño, verifica game over.
function Collision.updateEnemyBullets(g, dt)
  local player = g.player
  local px, py, pr = player.x, player.y, player.radius
  local i = 1
  while i <= g.enemyBulletCount do
    local b = g.enemyBullets[i]
    if not b:update(dt) then
      g:removeEnemyBullet(i)
    elseif Collision.circle(px, py, pr, b.x, b.y, b.radius) then
      g:removeEnemyBullet(i)
      g.shake:trigger(4, 0.15)
      local dmgReduce = player:getDamageReduction()
      if dmgReduce > 0 and love.math.random() < dmgReduce then
        -- damage reduced
      elseif player:hit() then
        g.effects:explode(px, py, {0.3, 0.8, 1}, 20, 200)
        Audio.play("hit")
      end
      if player.lives <= 0 then
        State.gameOver(g)
      end
    else
      i = i + 1
    end
  end
end

--- Detecta colisión entre balas del jugador y enemigos.
-- Para cada enemigo (iterando hacia atrás), verifica contra cada bala.
-- Al matar: combo++, score, coins, lifesteal, onKillBoost, powerups.
-- Optimizado: caching de references (effects, shake, bullets, enemies).
function Collision.bulletsVsEnemies(g)
  local combo = g.combo
  local score = g.score
  local totalKills = g.totalKills
  local maxCombo = g.maxCombo
  local player = g.player
  local effects = g.effects
  local shake = g.shake
  local bullets = g.bullets
  local enemies = g.enemies

  local ei = g.enemyCount
  while ei >= 1 do
    local enemy = enemies[ei]
    if not enemy then break end
    local ex, ey, er = enemy.x, enemy.y, enemy.radius
    local hit = false

    local bi = g.bulletCount
    while bi >= 1 do
      local bullet = bullets[bi]
      if bullet and bullet.alive then
        local dx = ex - bullet.x
        local dy = ey - bullet.y
        local minDist = er + bullet.radius
        if dx * dx + dy * dy < minDist * minDist then
          local dmg = bullet:getDamage()
          local isCrit = bullet:isCrit()

          bullet.alive = false
          g:removeBullet(bi)

          local killed = enemy:hit(dmg)
          effects:muzzleFlash(ex, ey)
          Audio.play("hit")
          shake:trigger(2, 0.08)

          if isCrit then
            effects:comboText(ex, ey, "CRIT!")
          end

          if killed then
            combo = combo + 1
            if combo > maxCombo then maxCombo = combo end
            local bonus = math.min(combo, 10)
            score = score + enemy.points * bonus
            totalKills = totalKills + 1
            effects:explode(ex, ey, enemy.color, 16, 200)
            if combo >= 3 then
              effects:comboText(ex, ey, combo)
            end
            Audio.play("explosion")
            shake:trigger(3, 0.12)

            local lifesteal = player:getLifesteal()
            if lifesteal > 0 then
              player.lives = math.min(player.lives + 1, player.maxLives + 2)
            end

            local boost = player:getOnKillBoost()
            if boost > 0 then
              player.speedTimer = player.speedTimer + 2
              player.hasSpeedItem = true
            end

            local coinMult = player:getCoinMultiplier()
            CurrencyManager.add(math.floor(CurrencyManager.getEnemyReward(g.wave) * coinMult))
            effects:coinPickup(ex, ey)

            SpawnManager.trySpawnPowerup(g, ex, ey)
            g:removeEnemy(ei)
          end

          local onHitRegen = player:getOnHitRegen()
          if onHitRegen > 0 then
            player.shieldVal = math.min(player:getStats().shield or 50, player.shieldVal + onHitRegen)
          end

          hit = true
          break
        end
      end
      bi = bi - 1
    end

    if not hit then
      ei = ei - 1
    end
  end

  g.combo = combo
  g.score = score
  g.totalKills = totalKills
  g.maxCombo = maxCombo
end

--- Detecta colisión entre balas del jugador y el jefe.
-- Similar a bulletsVsEnemies pero contra el boss activo.
-- Al matar: score, coins, lifesteal, explosiones, super boss handling.
function Collision.bulletsVsBoss(g)
  -- Checks player bullets against the boss (single active boss).
  -- On hit: applies damage, onHitRegen, lifesteal, coin rewards,
  -- powerup drops, and delegates to WaveManager on defeat.
  -- Handles multi-phase super boss via SuperBossManager.
  if not g.boss or not g.boss.alive then return end
  local boss = g.boss
  local player = g.player

  local bi = g.bulletCount
  while bi >= 1 do
    local bullet = g.bullets[bi]
    if bullet and bullet.alive and Collision.circle(boss.x, boss.y, boss.radius, bullet.x, bullet.y, bullet.radius) then
      local dmg = bullet:getDamage()
      local isCrit = bullet:isCrit()

      bullet.alive = false
      g:removeBullet(bi)

      local killed = boss:hit(dmg)
      g.effects:muzzleFlash(bullet.x, bullet.y)
      Audio.play("hit")
      g.shake:trigger(2, 0.08)

      if isCrit then
        g.effects:comboText(boss.x, boss.y - 20, "CRIT!")
      end

      -- onHit regen
      local onHitRegen = player:getOnHitRegen()
      if onHitRegen > 0 then
        local stats = player:getStats()
        player.shieldVal = math.min(stats.shield or 50, player.shieldVal + onHitRegen)
      end

      if killed then
        g.score = g.score + boss.scoreValue
        g.totalKills = g.totalKills + 1

        -- lifesteal on boss kill
        local lifesteal = player:getLifesteal()
        if lifesteal > 0 then
          local stats = player:getStats()
          player.shieldVal = math.min(stats.shield or 50, player.shieldVal + 20)
        end

        g.effects:explode(boss.x, boss.y, boss.color, 40, 300)
        g.effects:explode(boss.x - 20, boss.y, {1, 0.5, 0.2}, 20, 200)
        g.effects:explode(boss.x + 20, boss.y, {1, 0.5, 0.2}, 20, 200)
        Audio.play("explosion")
        g.shake:trigger(8, 0.3)

        if boss.isSuperBoss then
          local SuperBossManager = require("src.managers.super_boss_manager")
          local phaseContinued = SuperBossManager.onPhaseDefeated(g)
          if phaseContinued then
            local coinReward = boss.superCoins or CurrencyManager.getSuperBossReward(g.wave)
            local coinMult = player:getCoinMultiplier()
            CurrencyManager.add(math.floor(coinReward * coinMult))
            g.effects:coinPickup(boss.x, boss.y)
            break
          end
        end

        local coinReward = CurrencyManager.getBossReward(g.wave)
        local coinMult = player:getCoinMultiplier()
        CurrencyManager.add(math.floor(coinReward * coinMult))
        g.effects:coinPickup(boss.x, boss.y)

        for j = 1, 3 do
          if lume.random() < 0.5 then
            g:addPowerup(boss.x + lume.random(-30, 30), boss.y + lume.random(-20, 20))
          end
        end

        local WaveManager = require("src.managers.wave_manager")
        WaveManager.onBossDefeated(g)
      end
      break
    else
      bi = bi - 1
    end
  end
end

--- Detecta colisión entre enemigos y el jugador (contacto directo).
-- Al colisionar: elimina enemigo, resetea combo, aplica daño.
-- Importante: no incrementa i después de removeEnemy (swap-remove).
function Collision.enemiesVsPlayer(g)
  local player = g.player
  local px, py, pr = player.x, player.y, player.radius
  local i = 1
  while i <= g.enemyCount do
    local enemy = g.enemies[i]
    if enemy and Collision.circle(px, py, pr, enemy.x, enemy.y, enemy.radius) then
      g.effects:explode(enemy.x, enemy.y, {1, 0.5, 0.2}, 20, 250)
      g:removeEnemy(i)
      g.combo = 0
      g.shake:trigger(5, 0.2)
      local dmgReduce = player:getDamageReduction()
      if dmgReduce > 0 and love.math.random() < dmgReduce then
        -- damage reduced
      elseif player:hit() then
        g.effects:explode(px, py, {0.3, 0.8, 1}, 20, 200)
        Audio.play("hit")
      end
      if player.lives <= 0 then
        CurrencyManager.save()
        State.gameOver(g)
      end
      -- do NOT increment i: g:removeEnemy(i) swapped the last enemy into position i
    else
      i = i + 1
    end
  end
end

--- Actualiza powerups: movimiento, imán, y recolección.
-- Si el jugador tiene imán, los powerups se mueven hacia él.
-- Si están lo suficientemente cerca, se recolectan.
function Collision.updatePowerups(g, dt)
  local player = g.player
  local px, py, pr = player.x, player.y, player.radius
  local magnetRange = UpgradeManager.getEffect("magnetRange")

  local i = 1
  while i <= g.powerupCount do
    local p = g.powerups[i]
    p:update(dt)
    if not p.alive then
      g:removePowerup(i)
    else
      local collectDist = (player.hasMagnet and 1) or 1
      collectDist = collectDist * magnetRange
      local fullDist = pr + p.radius
      if Collision.circle(px, py, fullDist * collectDist, p.x, p.y, p.radius) then
        if Collision.circle(px, py, fullDist, p.x, p.y, p.radius) then
          player:collectPowerup(p.type, p.duration)
          g.effects:powerupCollect(p.x, p.y, p.color)
          Audio.play("hit")
          g:removePowerup(i)
        else
          local dx = px - p.x
          local dy = py - p.y
          local nd = sqrt(dx * dx + dy * dy)
          if nd > 0 then
            p.x = p.x + (dx / nd) * 200 * dt
            p.y = p.y + (dy / nd) * 200 * dt
          end
          i = i + 1
        end
      else
        i = i + 1
      end
    end
  end
end

return Collision
