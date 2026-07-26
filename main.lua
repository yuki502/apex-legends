-- main.lua
-- Punto de entrada del juego. Maneja todos los callbacks de LÖVE.
-- Inicializa Screen, Logger, DevMode, Lifecycle y el juego principal.
-- Coordina el game loop: update → draw, y maneja entrada de touch/mouse/keyboard.
-- Este archivo NO contiene lógica de juego, solo orquestación.

local Game = require("src.game")
local Screen = require("src.graphics.screen")
local Logger = require("src.utils.logger")
local Lifecycle = require("src.systems.lifecycle")
local DevMode = require("src.utils.dev_mode")

-- ═══════════════════════════════════════════════════════
-- ESTADO GLOBAL
-- ═══════════════════════════════════════════════════════

local game             -- Instancia principal del juego
local log              -- Instancia del logger
local devModeEnabled   -- Si el modo desarrollador está activo

-- ═══════════════════════════════════════════════════════
-- INICIALIZACIÓN
-- ═══════════════════════════════════════════════════════

--- Callback de LÖVE: se ejecuta una vez al iniciar el juego.
function love.load()
  love.graphics.setBackgroundColor(0, 0, 0)
  love.keyboard.setKeyRepeat(false)
  Screen.init()

  -- Cargar configuración primero (necesario para devMode y logToFile)
  local SettingsManager = require("src.managers.settings_manager")
  SettingsManager.init()

  devModeEnabled = SettingsManager.isDevMode()

  -- Configurar logger según configuración guardada
  log = Logger:new({
    minLevel = devModeEnabled and Logger.levels.DEBUG or Logger.levels.INFO,
    toFile = SettingsManager.isLogToFile(),
    toConsole = true,
  })
  if SettingsManager.get("logToFile") then
    log:startSession()
  end

  log:info("Game starting...")
  log:info("LÖVE version: %s", love.getVersion())
  log:info("Screen: %dx%d", love.graphics.getWidth(), love.graphics.getHeight())

  -- Inicializar modo desarrollador
  DevMode.init()
  DevMode.setEnabled(devModeEnabled)
  DevMode.collectStats()

  -- Crear juego y vincular lifecycle
  game = Game()
  Lifecycle.setGame(game)
  log:info("Game initialized")
end

-- ═══════════════════════════════════════════════════════
-- GAME LOOP
-- ═══════════════════════════════════════════════════════

--- Callback de LÖVE: se ejecuta cada frame para actualizar el estado.
-- Clamps dt a 0.1 para evitar saltos grandes al volver de pausa.
-- Si DevMode está activo, aplica pause y game speed adjustments.
-- @param dt Delta time en segundos
function love.update(dt)
  -- Prevenir saltos de tiempo grandes (ej: al cambiar de pestaña)
  if dt > 0.1 then dt = 0.1 end

  -- Procesar DevMode primero (puede pausar o ajustar velocidad)
  if DevMode.isEnabled() then
    DevMode.collectStats(game)
    DevMode.update(dt)

    -- Si DevMode está pausado, solo actualizar efectos visuales
    if DevMode.isPaused() and not DevMode.shouldStep() then
      if game.effects then game.effects:update(dt) end
      if game.shake then game.shake:update(dt) end
      return
    end

    -- Aplicar game speed multiplier
    local speed = DevMode.getGameSpeed()
    if speed ~= 1.0 then
      dt = dt * speed
    end
  end

  game:update(dt)
end

--- Callback de LÖVE: se ejecuta cada frame para renderizar.
-- Orden: letterbox → viewport scaling → game → DevMode overlay → pop
function love.draw()
  Screen.drawLetterbox()  -- Dibujar barras letterbox
  Screen.apply()          -- Push + escalar a viewport virtual
  game:draw()             -- Renderizar todo el juego
  DevMode.draw()          -- Overlay de estadísticas (encima del juego)
  Screen.clear()          -- Pop del transform
end

-- ═══════════════════════════════════════════════════════
-- ENTRADA: KEYBOARD
-- ═══════════════════════════════════════════════════════

--- Callback de LÖVE: tecla presionada.
-- Procesa teclas de DevMode (F3-F6) y escape.
-- En hangar, delega al hangar para manejo de teclado.
-- @param key Nombre de la tecla (ej: "escape", "f3")
function love.keypressed(key)
  -- Teclas de DevMode (se procesan siempre que esté habilitado)
  if DevMode.isEnabled() then
    if key == "f3" then
      DevMode.toggleOverlay()
      return
    end
    if key == "f4" then
      DevMode.toggleHitboxes()
      return
    end
    if key == "f5" then
      DevMode.togglePause()
      return
    end
    if key == "f6" then
      -- Toggle entre 2x y 1x speed
      DevMode.setGameSpeed(DevMode.getGameSpeed() >= 2 and 1 or 2)
      return
    end
  end

  -- Hangar tiene su propio manejo de teclado
  if game.state == "hangar" then
    if game.hangar then
      game.hangar:keypressed(key)
    end
    return
  end

  -- Escape cierra el juego
  if key == "escape" then
    love.event.quit()
  end
end

-- ═══════════════════════════════════════════════════════
-- ENTRADA: MOUSE / TOUCH
-- ═══════════════════════════════════════════════════════

--- Convierte coordenadas de pantalla a coordenadas virtuales.
-- @param x Coordenada X de pantalla
-- @param y Coordenada Y de pantalla
-- @return vx, vy Coordenadas virtuales
local function toVirtual(x, y)
  return Screen.toVirtual(x, y)
end

--- Callback de LÖVE: rueda del mouse (solo para hangar scroll).
function love.wheelmoved(x, y)
  if game and game.hangar then
    game.hangar:mousewheel(y)
  end
end

--- Callback de LÖVE: mouse movido (solo para hangar drag).
function love.mousemoved(x, y, dx, dy)
  if game and game.hangar then
    local vx, vy = toVirtual(x, y)
    local vdx, vdy = dx * Screen.getScale(), dy * Screen.getScale()
    game.hangar:mousemoved(vx, vy, vdx, vdy)
  end
end

--- Callback de LÖVE: touch presionado.
-- Convierte a coordenadas virtuales antes de enviar al juego.
function love.touchpressed(id, x, y)
  local vx, vy = toVirtual(x, y)
  game:touchpressed(id, vx, vy)
end

--- Callback de LÖVE: touch movido.
function love.touchmoved(id, x, y)
  local vx, vy = toVirtual(x, y)
  game:touchmoved(id, vx, vy)
end

--- Callback de LÖVE: touch liberado.
function love.touchreleased(id)
  game:touchreleased(id)
end

--- Callback de LÖVE: mouse presionado.
-- Convierte a coordenadas virtuales y delega al juego.
-- En hangar, delega al hangar directamente.
function love.mousepressed(x, y, button)
  if button == 1 then
    local vx, vy = toVirtual(x, y)
    if game.state == "hangar" then
      game.hangar:mousepressed(vx, vy, button)
      return
    end
    game:touchpressed(0, vx, vy)
  end
end

--- Callback de LÖVE: mouse liberado.
function love.mousereleased(x, y, button)
  if button == 1 then
    game:touchreleased(0)
  end
end

-- ═══════════════════════════════════════════════════════
-- EVENTOS DE SISTEMA
-- ═══════════════════════════════════════════════════════

--- Callback de LÖVE: ventana redimensionada.
-- Recalcula viewport y notifica al shader.
function love.resize(w, h)
  Screen.update()
  if game and game.shader then
    game.shader:resize()
  end
  if log then log:info("Window resized: %dx%d", w, h) end
end

--- Callback de LÖVE: foco de ventana cambiado.
-- Pausa automáticamente al perder foco.
function love.focus(f)
  Lifecycle.onFocus(f)
end

--- Callback de LÖVE: visibilidad cambiada (útil en móviles).
function love.visible(v)
  Lifecycle.onVisible(v)
end

--- Callback de LÖVE: juego cerrándose.
-- Guarda todos los datos y finaliza sesión de logging.
function love.quit()
  if log then
    log:info("Game shutting down")
    Lifecycle.quit()
    log:endSession()
  else
    Lifecycle.quit()
  end
end
