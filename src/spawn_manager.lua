local lume = require("lib.lume")
local Bullet = require("src.bullet")

local SpawnManager = {}

function SpawnManager.update(g, dt)
  if g.state ~= "playing" or g.paused or not g.waveActive then return end

  SpawnManager.spawnEnemies(g, dt)
  SpawnManager.updateBoss(g, dt)
  SpawnManager.updateEnemyShooting(g, dt)
end

function SpawnManager.spawnEnemies(g, dt)
  if g.bossWave then return end
  g.spawnTimer = g.spawnTimer - dt
  if g.spawnTimer <= 0 and g.enemiesSpawned < g.enemiesInWave then
    g:addEnemy(g.wave)
    g.enemiesSpawned = g.enemiesSpawned + 1
    g.spawnTimer = g.spawnRate
  end
end

function SpawnManager.updateBoss(g, dt)
  if not g.boss then return end
  g.boss:update(dt)
  if g.boss:canShoot() then
    local bossBullets, bulletCount = g.boss:getBullets()
    for j = 1, bulletCount do
      local bb = bossBullets[j]
      local b = Bullet(bb.x, bb.y, true)
      b:directed(bb.x, bb.y, bb.vx, bb.vy)
      g:addEnemyBullet(b)
    end
  end
end

function SpawnManager.updateEnemyShooting(g, dt)
  local player = g.player
  if not player then return end
  local px, py = player.x, player.y
  for i = 1, g.enemyCount do
    local enemy = g.enemies[i]
    if enemy and enemy.alive and enemy:canShoot() then
      local bullets = enemy:getBullets(px, py)
      if bullets then
        for j = 1, #bullets do
          local bb = bullets[j]
          if bb then
            local b = Bullet(bb.x, bb.y, true)
            b:directed(bb.x, bb.y, bb.vx, bb.vy)
            g:addEnemyBullet(b)
          end
        end
      end
    end
  end
end

function SpawnManager.trySpawnPowerup(g, x, y)
  if lume.random() < 0.08 then
    g:addPowerup(x, y)
  end
end

return SpawnManager
