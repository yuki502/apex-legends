local State = {}

function State.startWave(g)
  local WaveManager = require("src.wave_manager")
  WaveManager.startWave(g)
end

function State.gameOver(g)
  local Audio = require("src.audio")
  local CurrencyManager = require("src.currency_manager")
  g.effects:explode(g.player.x, g.player.y, {0.3, 0.8, 1}, 40, 300)
  Audio.play("explosion")
  Audio.stopMusic()
  Audio.play("gameover")
  g.shake:trigger(10, 0.4)
  CurrencyManager.save()
  if g.score > g.highScore then
    g.highScore = g.score
    State.saveHighScore(g)
  end
  g.state = "gameover"
end

function State.reset(g)
  local Effects = require("src.effects")
  local Shake = require("src.shake")
  local Audio = require("src.audio")
  local ShipDesigns = require("src.ship_designs")
  local UpgradeManager = require("src.upgrade_manager")
  local ConsumableManager = require("src.consumable_manager")
  local SettingsManager = require("src.settings_manager")
  local Inventory = require("src.inventory")

  g.inventory = Inventory()
  g.hangar = nil

  local design = ShipDesigns.get(g.selectedDesign)
  g.player = require("src.player")(design, g.inventory)

  g.player.maxLives = 3 + UpgradeManager.getLevel("maxHp")
  g.player.lives = g.player.maxLives

  g.effects = Effects()
  g.shake = Shake()
  g.state = "playing"
  g.wave = 0
  g.waveActive = false
  g.waveDelay = 1.0
  g.waveCountdown = nil
  g.bullets = {}
  g.bulletCount = 0
  g.enemyBullets = {}
  g.enemyBulletCount = 0
  g.enemies = {}
  g.enemyCount = 0
  g.powerups = {}
  g.powerupCount = 0
  g.boss = nil
  g.score = 0
  g.combo = 0
  g.maxCombo = 0
  g.totalKills = 0
  g.spawnTimer = 0
  g.spawnRate = 1.2
  g.paused = false
  g.leftHanded = SettingsManager.isLeftHanded()
  g.componentDropPool = {}
  Audio.playGameMusic()
end

function State.enterShop(g)
  g.state = "shop"
  local ShopManager = require("src.shop_manager")
  ShopManager.open()
end

function State.exitShop(g)
  g.state = "playing"
  g.waveActive = false
  g.waveDelay = 0.5
end

function State.loadHighScore(g)
  local ok, data = pcall(love.filesystem.read, "highscore.dat")
  g.highScore = (ok and data and tonumber(data)) or 0
end

function State.saveHighScore(g)
  pcall(love.filesystem.write, "highscore.dat", tostring(g.highScore))
end

return State
