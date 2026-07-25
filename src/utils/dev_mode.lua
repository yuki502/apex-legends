-- dev_mode.lua
-- Herramientas de desarrollo integradas para debugging y testing.
-- Proporciona overlay de estadísticas, renderizado de hitboxes,
-- control de velocidad del juego, pausa por frame, y teclas de acceso rápido.
-- Cuando está desactivado, tiene overhead mínimo (1 tabla lookup por frame).

local DevMode = {}
DevMode.__index = DevMode

local lg = love.graphics
local lk = love.keyboard

-- ═══════════════════════════════════════════════════════
-- ESTADO
-- ═══════════════════════════════════════════════════════

local font = nil               -- Fuente para el overlay
local lineH = 14               -- Altura de línea del overlay
local padding = 6              -- Espaciado del overlay

local _enabled = false         -- Estado global del modo desarrollador
local _stats = {}              -- Estadísticas actuales
local _showHitboxes = false    -- Mostrar círculos de colisión
local _showOverlay = true      -- Mostrar overlay de estadísticas
local _gameSpeed = 1.0         -- Multiplicador de velocidad (1.0 = normal)
local _paused = false          -- Pausa de desarrollador (separada de la pausa del juego)
local _stepFrame = false       -- Avanzar un solo frame
local _gcTrigger = 0           -- Temporizador para GC periódico

-- ═══════════════════════════════════════════════════════
-- INICIALIZACIÓN
-- ═══════════════════════════════════════════════════════

--- Inicializa el sistema de modo desarrollador.
-- Crea la fuente para el overlay y resetea las estadísticas.
function DevMode.init()
  font = lg.newFont(11)
  _enabled = false
  _stats = {
    fps = 0,
    frameTime = 0,
    memory = 0,
    entities = 0,
    bullets = 0,
    enemies = 0,
    particles = 0,
    powerups = 0,
    poolSize = 0,
  }
  _gcTrigger = 0
end

-- ═══════════════════════════════════════════════════════
-- ESTADO / TOGGLES
-- ═══════════════════════════════════════════════════════

--- Activa o desactiva el modo desarrollador.
-- @param v true para activar, false para desactivar
function DevMode.setEnabled(v)
  _enabled = v
end

--- Verifica si el modo desarrollador está activo.
-- @return true si está activo
function DevMode.isEnabled()
  return _enabled
end

--- Alterna el estado del modo desarrollador.
-- @return Nuevo estado (true/false)
function DevMode.toggle()
  _enabled = not _enabled
  return _enabled
end

--- Alterna la visibilidad de hitboxes.
function DevMode.toggleHitboxes()
  _showHitboxes = not _showHitboxes
end

--- Verifica si se deben mostrar hitboxes.
-- @return true si se deben mostrar
function DevMode.showHitboxes()
  return _showHitboxes and _enabled
end

--- Alterna la visibilidad del overlay de estadísticas.
function DevMode.toggleOverlay()
  _showOverlay = not _showOverlay
end

-- ═══════════════════════════════════════════════════════
-- VELOCIDAD DEL JUEGO
-- ═══════════════════════════════════════════════════════

--- Obtiene el multiplicador de velocidad actual.
-- @return Multiplicador de velocidad (1.0 = normal)
function DevMode.getGameSpeed()
  return _gameSpeed
end

--- Establece el multiplicador de velocidad del juego.
-- @param speed Velocidad (0.1 a 10.0)
function DevMode.setGameSpeed(speed)
  _gameSpeed = math.max(0.1, math.min(10, speed))
end

-- ═══════════════════════════════════════════════════════
-- PAUSA DE DESARROLLADOR
-- ═══════════════════════════════════════════════════════

--- Verifica si el juego está pausado por el desarrollador.
-- @return true si está pausado
function DevMode.isPaused()
  return _paused
end

--- Alterna la pausa de desarrollador.
function DevMode.togglePause()
  _paused = not _paused
end

--- Avanza un solo frame y pausa el juego.
-- Útil para debugging frame-by-frame.
function DevMode.stepFrame()
  _stepFrame = true
  _paused = true
end

--- Verifica si se debe avanzar un frame.
-- Llamado desde love.update, retorna true una vez y luego false.
-- @return true si se debe ejecutar un frame
function DevMode.shouldStep()
  if _stepFrame then
    _stepFrame = false
    return true
  end
  return false
end

-- ═══════════════════════════════════════════════════════
-- ACTUALIZACIÓN
-- ═══════════════════════════════════════════════════════

--- Actualiza las estadísticas y procesa teclas de acceso rápido.
-- Llamar desde love.update(dt) SIEMPRE (incluso cuando _enabled es false).
-- Las teclas F8 se procesan incluso cuando está desactivado.
-- @param dt Delta time
function DevMode.update(dt)
  -- F8 funciona siempre para activar/desactivar el modo
  if lk.isDown("f8") and not DevMode._f8 then
    DevMode._f8 = true
    DevMode.toggle()
  elseif not lk.isDown("f8") then
    DevMode._f8 = false
  end

  -- Si está desactivado, no procesar nada más
  if not _enabled then return end

  -- Actualizar estadísticas básicas
  _stats.fps = love.timer.getFPS()
  _stats.frameTime = dt * 1000

  -- GC periódico cada 5 segundos para medir memoria
  _gcTrigger = _gcTrigger + dt
  if _gcTrigger > 5 then
    _stats.memory = collectgarbage("count")
    _gcTrigger = 0
  end

  -- F3: toggle overlay
  if lk.isDown("f3") and not DevMode._f3 then
    DevMode._f3 = true
    DevMode.toggleOverlay()
  elseif not lk.isDown("f3") then
    DevMode._f3 = false
  end

  -- F4: toggle hitboxes
  if lk.isDown("f4") and not DevMode._f4 then
    DevMode._f4 = true
    DevMode.toggleHitboxes()
  elseif not lk.isDown("f4") then
    DevMode._f4 = false
  end

  -- F5: resetear velocidad a 1x
  if lk.isDown("f5") and not DevMode._f5 then
    DevMode._f5 = true
    DevMode.setGameSpeed(1.0)
  elseif not lk.isDown("f5") then
    DevMode._f5 = false
  end
end

-- ═══════════════════════════════════════════════════════
-- RECOLECCIÓN DE ESTADÍSTICAS
-- ═══════════════════════════════════════════════════════

--- Recopila estadísticas del juego actual para el overlay.
-- Llamar desde love.update después de Game:update().
-- @param game Instancia del juego actual
function DevMode.collectStats(game)
  if not _enabled then return end
  if not game then return end

  _stats.entities = (game.enemyCount or 0) + (game.bulletCount or 0) + (game.enemyBulletCount or 0) + (game.powerupCount or 0)
  _stats.bullets = (game.bulletCount or 0) + (game.enemyBulletCount or 0)
  _stats.enemies = game.enemyCount or 0
  _stats.powerups = game.powerupCount or 0
  _stats.memory = collectgarbage("count")
end

-- ═══════════════════════════════════════════════════════
-- RENDERIZADO
-- ═══════════════════════════════════════════════════════

--- Dibuja el overlay de estadísticas en la esquina superior izquierda.
-- Muestra FPS, tiempo de frame, memoria, y conteo de entidades.
function DevMode.draw()
  if not _enabled or not _showOverlay then return end

  local oldFont = lg.getFont()
  lg.setFont(font)

  local y = padding
  local x = padding

  -- Fondo semitransparente
  lg.setColor(0, 0, 0, 0.6)
  lg.rectangle("fill", 0, 0, 210, 160)

  -- Texto verde brillante
  lg.setColor(0.3, 1.0, 0.3)

  local lines = {
    string.format("FPS: %d", _stats.fps),
    string.format("Frame: %.2f ms", _stats.frameTime),
    string.format("Memory: %.1f KB", _stats.memory),
    "",
    string.format("Entities: %d", _stats.entities),
    string.format(" Bullets: %d", _stats.bullets),
    string.format(" Enemies: %d", _stats.enemies),
    string.format(" Powerups: %d", _stats.powerups),
  }

  for _, line in ipairs(lines) do
    lg.print(line, x, y)
    y = y + lineH
  end

  -- Indicadores de estado (solo si están activos)
  lg.setColor(1, 1, 0, 0.5)
  if _gameSpeed ~= 1.0 then
    lg.print(string.format("Speed: %.1fx", _gameSpeed), x, y)
    y = y + lineH
  end
  if _paused then
    lg.print("PAUSED (dev)", x, y)
    y = y + lineH
  end

  lg.setFont(oldFont)
  lg.setColor(1, 1, 1, 1)
end

--- Dibuja el hitbox de una entidad.
-- Muestra el radio de colisión como círculo verde semitransparente.
-- @param entity Entidad con propiedades x, y, radius
function DevMode.drawHitbox(entity)
  if not _enabled or not _showHitboxes then return end
  if not entity or not entity.x or not entity.y then return end

  local r = entity.radius or 10

  -- Borde verde
  lg.setColor(0, 1, 0, 0.3)
  lg.circle("line", entity.x, entity.y, r)

  -- Relleno rojo semitransparente
  lg.setColor(1, 0, 0, 0.3)
  lg.circle("fill", entity.x, entity.y, r)

  lg.setColor(1, 1, 1, 1)
end

--- Dibuja texto de debugging en una posición específica.
-- @param x Posición X
-- @param y Posición Y
-- @param text Texto a mostrar
-- @param priority Prioridad (no implementado aún, para sorting futuro)
function DevMode.drawText(x, y, text, priority)
  if not _enabled then return end
  if not _showOverlay then return end

  local oldFont = lg.getFont()
  lg.setFont(font)
  lg.setColor(1, 1, 1, 0.8)
  lg.print(text, x, y - 10)
  lg.setFont(oldFont)
end

return DevMode
