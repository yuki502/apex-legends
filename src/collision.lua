local sqrt = math.sqrt
local min = math.min
local lume = require("lib.lume")
local Audio = require("src.audio")
local SpawnManager = require("src.spawn_manager")
local State = require("src.state")
local CurrencyManager = require("src.currency_manager")
local UpgradeManager = require("src.upgrade_manager")

local Collision = {}

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

function Collision.bulletsVsEnemies(g)
  local combo = g.combo
  local score = g.score
  local totalKills = g.totalKills
  local maxCombo = g.maxCombo
  local player = g.player

  local magnetRange = UpgradeManager.getEffect("magnetRange")

  local ei = g.enemyCount
  while ei >= 1 do
    local enemy = g.enemies[ei]
    if not enemy then break end
    local ex, ey, er = enemy.x, enemy.y, enemy.radius
    local hit = false

    local bi = g.bulletCount
    while bi >= 1 do
      local bullet = g.bullets[bi]
      if bullet and bullet.alive and Collision.circle(ex, ey, er, bullet.x, bullet.y, bullet.radius) then
        local dmg = bullet:getDamage()
        local isCrit = bullet:isCrit()

        bullet.alive = false
        g:removeBullet(bi)

        local killed = enemy:hit(dmg)
        g.effects:muzzleFlash(ex, ey)
        Audio.play("hit")
        g.shake:trigger(2, 0.08)

        if isCrit then
          g.effects:comboText(ex, ey, "CRIT!")
        end

        if killed then
          combo = combo + 1
          if combo > maxCombo then maxCombo = combo end
          local bonus = math.min(combo, 10)
          score = score + enemy.points * bonus
          totalKills = totalKills + 1
          g.effects:explode(ex, ey, enemy.color, 16, 200)
          if combo >= 3 then
            g.effects:comboText(ex, ey, combo)
          end
          Audio.play("explosion")
          g.shake:trigger(3, 0.12)

          -- lifesteal
          local lifesteal = player:getLifesteal()
          if lifesteal > 0 then
            player.lives = math.min(player.lives + 1, player.maxLives + 2)
          end

          -- onKillBoost
          local boost = player:getOnKillBoost()
          if boost > 0 then
            player.speedTimer = player.speedTimer + 2
            player.hasSpeedItem = true
          end

          local coinReward = CurrencyManager.getEnemyReward(g.wave)
          local coinMult = player:getCoinMultiplier()
          CurrencyManager.add(math.floor(coinReward * coinMult))
          g.effects:coinPickup(ex, ey)

          SpawnManager.trySpawnPowerup(g, ex, ey)
          g:removeEnemy(ei)
        end

        -- onHit regen for shield
        local onHitRegen = player:getOnHitRegen()
        if onHitRegen > 0 then
          local stats = player:getStats()
          player.shieldVal = math.min(stats.shield or 50, player.shieldVal + onHitRegen)
        end

        hit = true
        break
      else
        bi = bi - 1
      end
    end

    ei = ei - 1
  end

  g.combo = combo
  g.score = score
  g.totalKills = totalKills
  g.maxCombo = maxCombo
end

function Collision.bulletsVsBoss(g)
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
          local SuperBossManager = require("src.super_boss_manager")
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

        local WaveManager = require("src.wave_manager")
        WaveManager.onBossDefeated(g)
      end
      break
    else
      bi = bi - 1
    end
  end
end

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
    else
      i = i + 1
    end
  end
end

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
