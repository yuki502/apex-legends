-- game.lua
-- Módulo principal del juego. Orquesta todos los sistemas:
--   - Estado del juego (menu, playing, shop, hangar, gameover)
--   - Entidades (player, enemies, bullets, powerups, boss)
--   - Sistemas (collision, wave progression, spawning)
--   - UI (HUD, menus, touch controls)
--   - Rendering (background, shader, effects)
-- Gestiona el game loop completo: update → draw, y entrada de usuario.
-- Responsabilidades: inicialización, actualización, renderizado, pooling de entidades.

local Object = require("lib.classic")
local Input = require("src.systems.input")
local Audio = require("src.utils.audio")
local ShipDesigns = require("src.data.ship_designs")
local PostShader = require("src.graphics.post_shader")
local State = require("src.systems.state")
local WaveManager = require("src.managers.wave_manager")
local SpawnManager = require("src.managers.spawn_manager")
local Collision = require("src.systems.collision")
local HUD = require("src.ui.hud")
local Menus = require("src.ui.menus")
local Customize = require("src.ui.customize")
local TouchControls = require("src.ui.touch_controls")
local Bullet = require("src.entities.bullet")
local Enemy = require("src.entities.enemy")
local Powerup = require("src.entities.powerup")
local Background = require("src.graphics.background")
local SettingsManager = require("src.managers.settings_manager")
local CurrencyManager = require("src.managers.currency_manager")
local UpgradeManager = require("src.managers.upgrade_manager")
local ConsumableManager = require("src.managers.consumable_manager")
local ShopManager = require("src.managers.shop_manager")
local Inventory = require("src.utils.inventory")
local Hangar = require("src.ui.hangar")
local ComponentDefs = require("src.data.component_defs")
local Loading = require("src.ui.loading")
local Screen = require("src.graphics.screen")
local C = require("src.data.constants")
local DevMode = require("src.utils.dev_mode")
local Logger = require("src.utils.logger")

local lg = love.graphics
local lw = Screen.getWidth
local lh = Screen.getHeight

local Game = Object:extend()
local log = Logger.getInstance()

--- Constructor del juego.
-- Inicializa todas las entidades, sistemas, fuentes y configuración.
-- Las loading tasks se ejecutan secuencialmente en love.update.
function Game:new()
  local w, h = lw(), lh()

  -- ═══════════════════════════════════════════════════════
  -- SISTEMAS BASE
  -- ═══════════════════════════════════════════════════════

  self.input = Input()
  self.fireBtn = { x = w - C.FIRE_BTN_X_OFFSET, y = h / 2, radius = C.FIRE_BTN_RADIUS, radiusSq = C.FIRE_BTN_RADIUS_SQ }

  -- ═══════════════════════════════════════════════════════
  -- ENTIDADES
  -- ═══════════════════════════════════════════════════════

  self.player = nil          -- Jugador actual (se crea en startPlaying)
  self.bullets = {}          -- Balas del jugador (array plano, swap-remove)
  self.bulletCount = 0       -- Cantidad de balas activas
  self.enemyBullets = {}     -- Balas enemigas
  self.enemyBulletCount = 0  -- Cantidad de balas enemigas activas
  self.enemies = {}          -- Enemigos activos
  self.enemyCount = 0        -- Cantidad de enemigos activos
  self.powerups = {}         -- Powerups en pantalla
  self.powerupCount = 0      -- Cantidad de powerups activos
  self.boss = nil            -- Jefe actual (nil si no hay jefe)
  self.effects = nil         -- Sistema de partículas (se crea en startPlaying)
  self.shake = nil           -- Sistema de screen shake

  -- ═══════════════════════════════════════════════════════
  -- ESTADO DEL JUEGO
  -- ═══════════════════════════════════════════════════════

  self.score = 0             -- Puntuación actual
  self.highScore = 0         -- High score guardado
  self.wave = 0              -- Número de ola actual
  self.enemiesInWave = 0     -- Total de enemigos en la ola actual
  self.enemiesSpawned = 0    -- Enemigos ya generados en la ola
  self.waveDelay = 0         -- Temporizador entre olas
  self.waveActive = false    -- Si la ola actual está activa
  self.bossWave = false      -- Si es ola de jefe (cada 10 olas)
  self.spawnTimer = 0        -- Temporizador para spawning de enemigos
  self.spawnRate = C.SPAWN_INTERVAL_BASE  -- Intervalo entre spawns
  self.state = "loading"     -- Estado actual: loading/menu/customize/playing/shop/hangar/gameover
  self.combo = 0             -- Combo actual (kills consecutivas)
  self.maxCombo = 0          -- Combo máximo alcanzado
  self.menuFadeOut = 0       -- Progreso de animación fade-out del menú
  self.selectedDesign = 1    -- Diseño de nave seleccionado
  self.paused = false        -- Si el juego está pausado
  self.totalKills = 0        -- Total de kills en la partida

  -- ═══════════════════════════════════════════════════════
  -- FUENTES
  -- ═══════════════════════════════════════════════════════

  -- Todas las fuentes usan Screen.fontSize para escalado proporcional
  self.font = lg.newFont(Screen.fontSize(18))       -- Fuente principal
  self.bigFont = lg.newFont(Screen.fontSize(40))    -- Títulos grandes
  self.titleFont = lg.newFont(Screen.fontSize(22))  -- Títulos medianos
  self.smallFont = lg.newFont(Screen.fontSize(14))  -- Texto pequeño
  self.tinyFont = lg.newFont(Screen.fontSize(11))   -- Texto muy pequeño

  -- ═══════════════════════════════════════════════════════
  -- SISTEMAS VISUALES
  -- ═══════════════════════════════════════════════════════

  self.shader = PostShader()
  self.bgScrollY = 0
  self.leftHanded = false
  self.waveCountdown = nil
  self.itemBtns = {}
  self.menuTimer = 0

  self.loading = Loading()
  self._loadingTasks = {
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

  log:info("Game instance created")
end

--- Actualiza la pantalla de carga.
-- Ejecuta una task por frame para mantener la UI responsive.
-- Cuando terminan todas, cambia al estado "menu".
-- @param dt Delta time
-- @return true si sigue cargando, false si terminó
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

--- Inicializa una nueva partida.
-- Crea el inventario y carga los componentes instalados del hangar.
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

--- Inicia una nueva partida.
-- Resetea score, wave, combo, crea player/effects/shake,
-- y comienza la primera ola.
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
  self.player = require("src.entities.player")(design, self.inventory)
  self.effects = require("src.graphics.effects")()
  self.shake = require("src.systems.shake")()

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

--- Actualiza el estado del juego según el estado actual.
-- Maneja loading, menu, customize, playing, shop, hangar, gameover.
-- En estado "playing": actualiza wave, player, enemies, collision.
-- @param dt Delta time en segundos
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
    Audio.play("shoot")
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

--- Actualiza las luces del shader post-procesado.
-- Agrega luces en: jugador, balas enemigas, jefe, y centro del combo.
-- Solo se ejecuta si el shader es soportado.
function Game:_updateShaderLights()
  if not self.shader:isSupported() then return end
  self.shader:clearLights()

  if self.player then
    self.shader:addLight(self.player.x, self.player.y, 0.3, 0.7, 1.0, 2500.0)
  end

  local bullets = self.enemyBullets
  for i = 1, self.enemyBulletCount do
    local b = bullets[i]
    if b then
      self.shader:addLight(b.x, b.y, 1.0, 0.3, 0.2, 800.0)
    end
  end

  if self.boss and self.boss.alive then
    self.shader:addLight(self.boss.x, self.boss.y, 1.0, 0.2, 0.1, 5000.0)
  end

  if self.combo >= C.COMBO_THRESHOLD_MED then
    local px = self.player and self.player.x or lw() / 2
    local py = self.player and self.player.y or lh() / 2
    local comboColor = self.combo >= C.COMBO_THRESHOLD_HIGH and C.COMBO_COLOR_HIGH or C.COMBO_COLOR_LOW
    self.shader:addLight(px, py - 30, comboColor[1], comboColor[2], comboColor[3], 2000.0)
  end
end

--- Renderiza todo el juego según el estado actual.
-- Maneja el renderizado por estados: loading, menu, customize, shop, hangar, playing.
-- En "playing": dibuja background → shader → entities → UI.
-- Respeta el screen shake aplicando translate(ox, oy).
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

  if DevMode.showHitboxes() then
    if self.player then DevMode.drawHitbox(self.player) end
  end

  for i = 1, self.bulletCount do
    self.bullets[i]:draw()
    if DevMode.showHitboxes() then DevMode.drawHitbox(self.bullets[i]) end
  end
  for i = 1, self.enemyBulletCount do
    self.enemyBullets[i]:draw()
    if DevMode.showHitboxes() then DevMode.drawHitbox(self.enemyBullets[i]) end
  end
  for i = 1, self.enemyCount do
    self.enemies[i]:draw()
    if DevMode.showHitboxes() then DevMode.drawHitbox(self.enemies[i]) end
  end
  for i = 1, self.powerupCount do
    self.powerups[i]:draw()
  end
  if self.boss then
    self.boss:draw()
    if DevMode.showHitboxes() then DevMode.drawHitbox(self.boss) end
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

--- Agrega una bala del jugador en la posición dada.
-- Aplica stats de daño, velocidad, homing, ricochet, crit, lifesteal.
-- @param x Posición X de spawn
-- @param y Posición Y de spawn
-- @param stats Tabla de estadísticas del jugador
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

--- Elimina una bala por índice (swap-remove pattern).
-- Mueve la última bala al índice eliminado para O(1).
function Game:removeBullet(i)
  self.bullets[i] = self.bullets[self.bulletCount]
  self.bullets[self.bulletCount] = nil
  self.bulletCount = self.bulletCount - 1
end

--- Elimina una bala enemiga por índice (swap-remove pattern).
function Game:removeEnemyBullet(i)
  self.enemyBullets[i] = self.enemyBullets[self.enemyBulletCount]
  self.enemyBullets[self.enemyBulletCount] = nil
  self.enemyBulletCount = self.enemyBulletCount - 1
end

--- Elimina un enemigo por índice (swap-remove pattern).
function Game:removeEnemy(i)
  self.enemies[i] = self.enemies[self.enemyCount]
  self.enemies[self.enemyCount] = nil
  self.enemyCount = self.enemyCount - 1
end

--- Elimina un powerup por índice (swap-remove pattern).
function Game:removePowerup(i)
  self.powerups[i] = self.powerups[self.powerupCount]
  self.powerups[self.powerupCount] = nil
  self.powerupCount = self.powerupCount - 1
end

--- Maneja touch/mouse presionado.
-- Delega al sistema apropiado según el estado actual:
--   - hangar: drag-and-drop de componentes
--   - shop: compra de items
--   - customize: selección de nave
--   - playing: fire button, items, joystick
-- @param id ID del touch (0 para mouse)
-- @param tx Coordenada X virtual
-- @param ty Coordenada Y virtual
-- @return true si el evento fue manejado
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

--- Compra un componente de la tienda.
-- Verifica si hay suficientes créditos y agrega al inventario.
-- @param index Índice del componente en componentDropPool
-- @return true si la compra fue exitosa
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
