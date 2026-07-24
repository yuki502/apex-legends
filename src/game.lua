local Object = require("lib.classic")
local Input = require("src.input")
local Audio = require("src.audio")
local ShipDesigns = require("src.ship_designs")
local PostShader = require("src.post_shader")
local State = require("src.state")
local WaveManager = require("src.wave_manager")
local SpawnManager = require("src.spawn_manager")
local Collision = require("src.collision")
local HUD = require("src.hud")
local Menus = require("src.menus")
local Customize = require("src.customize")
local TouchControls = require("src.touch_controls")
local Bullet = require("src.bullet")
local Enemy = require("src.enemy")
local Powerup = require("src.powerup")
local Background = require("src.background")
local SettingsManager = require("src.settings_manager")
local CurrencyManager = require("src.currency_manager")
local UpgradeManager = require("src.upgrade_manager")
local ConsumableManager = require("src.consumable_manager")
local ShopManager = require("src.shop_manager")
local Inventory = require("src.inventory")
local Hangar = require("src.hangar")
local ComponentDefs = require("src.component_defs")
local Loading = require("src.loading")

local lg = love.graphics
local lw = lg.getWidth
local lh = lg.getHeight

local COMBO_COLOR_HIGH = {1.0, 0.2, 0.8}
local COMBO_COLOR_MED = {1.0, 0.8, 0.2}

local Game = Object:extend()

function Game:new()
  local w, h = lw(), lh()

  self.input = Input()
  self.fireBtn = { x = w - 60, y = h / 2, radius = 40, radiusSq = 2500 }

  self.player = nil
  self.bullets = {}
  self.bulletCount = 0
  self.enemyBullets = {}
  self.enemyBulletCount = 0
  self.enemies = {}
  self.enemyCount = 0
  self.powerups = {}
  self.powerupCount = 0
  self.boss = nil
  self.effects = nil
  self.shake = nil

  self.score = 0
  self.highScore = 0
  self.wave = 0
  self.enemiesInWave = 0
  self.enemiesSpawned = 0
  self.waveDelay = 0
  self.waveActive = false
  self.bossWave = false
  self.spawnTimer = 0
  self.spawnRate = 1.2
  self.state = "loading"
  self.combo = 0
  self.maxCombo = 0
  self.menuTimer = 0
  self.menuFadeOut = 0
  self.selectedDesign = 1
  self.paused = false
  self.totalKills = 0

  self.font = lg.newFont(18)
  self.bigFont = lg.newFont(40)
  self.titleFont = lg.newFont(22)
  self.smallFont = lg.newFont(14)
  self.tinyFont = lg.newFont(11)

  self.shader = PostShader()
  self.bgScrollY = 0
  self.leftHanded = false
  self.waveCountdown = nil
  self.itemBtns = {}
  self.menuTimer = 0

  -- Loading screen for asset initialization
  self.loading = Loading()
  self._loadingTasks = {
    { name = "Loading settings...", fn = function() SettingsManager.init() end },
    { name = "Loading currency...", fn = function() CurrencyManager.init() end },
    { name = "Loading upgrades...", fn = function() UpgradeManager.init() end },
    { name = "Loading consumables...", fn = function() ConsumableManager.init() end },
    { name = "Initializing background...", fn = function() Background.init(os.time()) end },
    { name = "Loading audio...", fn = function() Audio.load() end },
    { name = "Loading high score...", fn = function() State.loadHighScore(self) end },
    { name = "Starting menu music...", fn = function() Audio.playMenuMusic() end },
  }
  self.loading:start(self._loadingTasks)

  self.inventory = nil
  self.hangar = nil
  self.componentDropPool = {}
  self.leftHanded = SettingsManager.isLeftHanded()
  self._loadingIndex = 1
  self._loadingTotal = #self._loadingTasks
end

function Game:_updateLoading(dt)
  if self.state ~= "loading" then return false end

  local tasks = self._loadingTasks
  if not tasks then return false end

  -- Run one task per frame for smooth loading
  local task = tasks[self._loadingIndex]
  if task then
    if task.fn then
      local ok, err = pcall(task.fn)
      if not ok then
        print("Loading task failed:", task.name, err)
      end
    end
    self._loadingIndex = self._loadingIndex + 1
  end

  if self._loadingIndex > self._loadingTotal then
    self.state = "menu"
    self._loadingTasks = nil
    self._loadingIndex = nil
    self._loadingTotal = nil
  end
  return true
end

function Game:initRun()
  self.inventory = Inventory()

  local slots = {}
  for slotKey, slotInfo in pairs(ComponentDefs.SLOT_LAYOUT) do
    local compId = self.inventory:getInstalled(slotKey)
    if compId then
      slots[slotKey] = compId
    end
  end
end

function Game:startPlaying()
  self.state = "playing"
  self.wave = 0
  self.score = 0
  self.combo = 0
  self.totalKills = 0
  self.enemiesSpawned = 0
  self.bossWave = false
  self.waveDelay = 0
  self.spawnTimer = 0
  self.componentDropPool = {}

  local design = ShipDesigns[self.selectedDesign] or ShipDesigns[1]
  self.player = require("src.player")(design, self.inventory)
  self.effects = require("src.effects")()
  self.shake = require("src.shake")()

  self.bullets = {}
  self.bulletCount = 0
  self.enemyBullets = {}
  self.enemyBulletCount = 0
  self.enemies = {}
  self.enemyCount = 0
  self.powerups = {}
  self.powerupCount = 0
  self.boss = nil

  ConsumableManager.init()
  Audio.playGameMusic()
  self.paused = false

  WaveManager.startNextWave(self)
end

function Game:enterShop()
  self.state = "shop"

  -- sell components: random drops based on wave
  self.componentDropPool = {}
  local dropCount = 2 + math.floor(self.wave / 5)
  for i = 1, dropCount do
    local slots = {"weapon", "thruster", "core", "engine", "wing", "shield", "armor", "multiplier"}
    local slot = slots[love.math.random(1, #slots)]
    local comp = ComponentDefs.getRandomBySlot(slot, self.wave)
    if comp then
      local price = 10 + comp.rarity * 15 + math.floor(self.wave * 0.5)
      self.componentDropPool[#self.componentDropPool + 1] = {
        comp = comp,
        price = price,
        bought = false,
      }
    end
  end

  ShopManager.open(self)
end

function Game:enterHangar()
  self.state = "hangar"
  if not self.hangar then
    self.hangar = Hangar(self.inventory, self.effects)
  end
  self.hangar:refresh()
end

function Game:continueFromHangar()
  self.state = "playing"
  self.waveActive = false
  self.waveDelay = 0.5
end

function Game:continueFromShop()
  self:enterHangar()
end

function Game:togglePause()
  if self.state == "playing" then
    self.paused = not self.paused
  end
end

function Game:update(dt)
  -- Handle loading state first
  if self.state == "loading" then
    self:_updateLoading(dt)
    return
  end

  if self.effects then self.effects:update(dt) end
  if self.shake then self.shake:update(dt) end
  self.shader:update(dt)
  self.menuTimer = self.menuTimer + dt

  Background.update(dt, 0)

  if self.state == "menu" then
    if self.input:isFire() or self.input:isPause() then
      self.state = "menuFadeOut"
      self.menuFadeOut = 0
    end
    return
  end

  if self.state == "menuFadeOut" then
    self.menuFadeOut = self.menuFadeOut + dt * 2.5
    if self.menuFadeOut >= 1 then
      self.state = "customize"
      self.menuFadeOut = 0
    end
    return
  end

  if self.state == "customize" then
    Customize.handleInput(self)
    return
  end

  if self.state == "shop" then
    ShopManager.update(dt)
    return
  end

  if self.state == "hangar" then
    self.hangar:update(dt)
    if (love.keyboard.isDown("return") or love.keyboard.isDown("kpenter")) and not self._hangarEnterDown then
      self._hangarEnterDown = true
      self:continueFromHangar()
    elseif not love.keyboard.isDown("return") and not love.keyboard.isDown("kpenter") then
      self._hangarEnterDown = false
    end
    return
  end

  if self.state == "gameover" then
    if self.input:isFire() then
      State.reset(self)
    end
    return
  end

  if self.paused then
    if self.input:isPause() or self.input:isFire() then
      self.paused = false
    end
    return
  end

  if self.input:isPause() then
    self.paused = true
    return
  end

  WaveManager.update(self, dt)

  if not self.waveActive then return end

  local player = self.player
  local jdx, jdy = self.input:getMovement()
  player:update(dt, jdx, jdy)

  if self.input:isFireJustPressed() and player:canShoot() then
    local positions = player:getShootPositions()
    local stats = player:getStats()
    for i = 1, #positions do
      local pos = positions[i]
      self:addBullet(pos.x, pos.y, stats)
      self.effects:muzzleFlash(pos.x, pos.y - 6)
    end
    if #positions > 1 then
      Audio.play("shoot")
    else
      Audio.play("shoot")
    end
  end

  Collision.updateAll(self, dt)

  SpawnManager.update(self, dt)

  local i = 1
  while i <= self.enemyCount do
    local enemy = self.enemies[i]
    enemy:update(dt)
    if not enemy.alive then
      self:removeEnemy(i)
    else
      i = i + 1
    end
  end

  WaveManager.checkWaveComplete(self)
end

function Game:_updateShaderLights()
  if not self.shader:isSupported() then return end
  self.shader:clearLights()

  if self.player then
    self.shader:addLight(self.player.x, self.player.y, 0.3, 0.7, 1.0, 2500.0)
  end

  for i = 1, self.enemyBulletCount do
    local b = self.enemyBullets[i]
    if b then
      self.shader:addLight(b.x, b.y, 1.0, 0.3, 0.2, 800.0)
    end
  end

  if self.boss and self.boss.alive then
    self.shader:addLight(self.boss.x, self.boss.y, 1.0, 0.2, 0.1, 5000.0)
  end

  if self.combo >= 5 then
    local px = self.player and self.player.x or lw() / 2
    local py = self.player and self.player.y or lh() / 2
    local comboColor = self.combo >= 10 and COMBO_COLOR_HIGH or COMBO_COLOR_MED
    self.shader:addLight(px, py - 30, comboColor[1], comboColor[2], comboColor[3], 2000.0)
  end
end

function Game:draw()
  local ox, oy = self.shake and self.shake:getOffset() or 0, 0
  lg.push()
  lg.translate(ox, oy)

  if self.state == "loading" then
    if self.loading then self.loading:draw() end
    lg.pop()
    return
  end

  Background.draw()

  self.shader:setCamera(ox, oy)
  if self.shader:isSupported() then
    self:_updateShaderLights()
    self.shader:apply()
  end

  if self.effects then self.effects:draw() end

  if self.state == "menu" then
    Menus.drawMenu(self)
    if self.shader:isSupported() then self.shader:remove() end
    lg.pop()
    return
  end

  if self.state == "menuFadeOut" then
    Menus.drawMenu(self)
    Menus.drawFadeOut(self, self.menuFadeOut)
    if self.shader:isSupported() then self.shader:remove() end
    lg.pop()
    return
  end

  if self.state == "customize" then
    Customize.draw(self)
    if self.shader:isSupported() then self.shader:remove() end
    lg.pop()
    return
  end

  if self.state == "shop" then
    if self.player then self.player:draw() end
    if self.shader:isSupported() then self.shader:remove() end
    ShopManager.draw(self)
    TouchControls.draw(self)
    HUD.draw(self)
    lg.pop()
    return
  end

  if self.state == "hangar" then
    if self.player then self.player:draw() end
    if self.shader:isSupported() then self.shader:remove() end
    self.hangar:draw()
    HUD.draw(self)
    lg.pop()
    return
  end

  for i = 1, self.bulletCount do
    self.bullets[i]:draw()
  end
  for i = 1, self.enemyBulletCount do
    self.enemyBullets[i]:draw()
  end
  for i = 1, self.enemyCount do
    self.enemies[i]:draw()
  end
  for i = 1, self.powerupCount do
    self.powerups[i]:draw()
  end
  if self.boss then
    self.boss:draw()
  end
  self.player:draw()

  if self.shader:isSupported() then self.shader:remove() end

  TouchControls.draw(self)
  HUD.draw(self)

  if self.state == "gameover" then
    HUD.drawGameOver(self)
  end

  if self.paused then
    HUD.drawPause(self)
  end

  lg.pop()
end

function Game:addBullet(x, y, stats)
  stats = stats or {}
  self.bulletCount = self.bulletCount + 1
  local b = Bullet(x, y)
  b.damage = (b.damage or 1) * (stats.damage or 1)
  b.speed = (b.speed or 600) * (stats.projectileSpeed or 1)
  b.homing = stats.homing or 0
  b.ricochet = stats.ricochet or 0
  b.critChance = stats.critChance or 0
  b.lifesteal = stats.lifesteal or 0
  self.bullets[self.bulletCount] = b
end

function Game:addEnemyBullet(b)
  self.enemyBulletCount = self.enemyBulletCount + 1
  self.enemyBullets[self.enemyBulletCount] = b
end

function Game:addEnemy(wave)
  self.enemyCount = self.enemyCount + 1
  self.enemies[self.enemyCount] = Enemy(wave)
end

function Game:addPowerup(x, y)
  self.powerupCount = self.powerupCount + 1
  self.powerups[self.powerupCount] = Powerup(x, y)
end

function Game:removeBullet(i)
  self.bullets[i] = self.bullets[self.bulletCount]
  self.bullets[self.bulletCount] = nil
  self.bulletCount = self.bulletCount - 1
end

function Game:removeEnemyBullet(i)
  self.enemyBullets[i] = self.enemyBullets[self.enemyBulletCount]
  self.enemyBullets[self.enemyBulletCount] = nil
  self.enemyBulletCount = self.enemyBulletCount - 1
end

function Game:removeEnemy(i)
  self.enemies[i] = self.enemies[self.enemyCount]
  self.enemies[self.enemyCount] = nil
  self.enemyCount = self.enemyCount - 1
end

function Game:removePowerup(i)
  self.powerups[i] = self.powerups[self.powerupCount]
  self.powerups[self.powerupCount] = nil
  self.powerupCount = self.powerupCount - 1
end

function Game:touchpressed(id, tx, ty)
  if self.state == "hangar" then
    self.hangar:mousepressed(tx, ty, 1)
    return true
  end

  if self.state == "shop" then
    self.input:touchpressed(id, tx, ty)
    local handled = ShopManager.touchpressed(self, id, tx, ty)
    if not handled then
      ConsumableManager.use("repair", self)
    end
    return true
  end

  if self.state == "customize" then
    self.input:touchpressed(id, tx, ty)
    Customize.handleInput(self)
    return true
  end
  if self.state == "menu" or self.state == "menuFadeOut" or self.state == "gameover" then
    self.input:touchpressed(id, tx, ty)
    return true
  end

  local fireR = self.fireBtn.radius
  local fireDx = tx - self.fireBtn.x
  local fireDy = ty - self.fireBtn.y
  if fireDx * fireDx + fireDy * fireDy < fireR * fireR then
    self.input:firePressed_(id, tx, ty)
    return true
  end

  if self.itemBtns then
    for _, btn in ipairs(self.itemBtns) do
      local dx = tx - btn.x
      local dy = ty - btn.y
      if dx * dx + dy * dy < btn.r * btn.r then
        ConsumableManager.use(btn.key, self)
        return true
      end
    end
  end

  return self.input:touchpressed(id, tx, ty)
end

function Game:touchmoved(id, tx, ty)
  return self.input:touchmoved(id, tx, ty)
end

function Game:touchreleased(id)
  self.input:fireReleased_(id)
  return self.input:touchreleased(id)
end

function Game:purchaseComponent(index)
  local item = self.componentDropPool[index]
  if not item or item.bought then return false end
  if self.inventory:spendCredits(item.price) then
    self.inventory:add(item.comp.id)
    item.bought = true
    if self.effects then
      self.effects:coinPickup(lw() / 2, lh() / 2)
    end
    return true
  end
  return false
end

return Game
