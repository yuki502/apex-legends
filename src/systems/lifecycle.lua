-- lifecycle.lua
-- Maneja el ciclo de vida de la aplicación en móviles y desktop.
-- Detecta pérdida/ganancia de foco, visibilidad, y cierre.
-- Pausa automáticamente el juego al perder foco para evitar progreso no intencionado.
-- Preserva timers y animaciones al restaurar.

local Lifecycle = {}

-- ═══════════════════════════════════════════════════════
-- ESTADO INTERNO
-- ═══════════════════════════════════════════════════════

local _callbacks = {}      -- Callbacks registrados (extensibilidad futura)
local _gameRef = nil       -- Referencia al juego actual
local _wasPaused = false   -- Estado de pausa antes de perder foco

-- ═══════════════════════════════════════════════════════
-- CONFIGURACIÓN
-- ═══════════════════════════════════════════════════════

--- Registra la referencia al juego para manejar su estado.
-- @param game Instancia de Game
function Lifecycle.setGame(game)
  _gameRef = game
end

-- ═══════════════════════════════════════════════════════
-- CALLBACKS DE LOVE
-- ═══════════════════════════════════════════════════════

--- Maneja la pérdida/ganancia de foco de la ventana.
-- Al perder foco: pausa el juego si estaba jugando.
-- Al ganar foco: mantiene el estado de pausa anterior.
-- @param focus true si la ventana ganó foco, false si lo perdió
function Lifecycle.onFocus(focus)
  if not _gameRef then return end

  if not focus then
    -- Guardar estado de pausa actual antes de pausar
    _wasPaused = _gameRef.paused
    if _gameRef.state == "playing" and not _gameRef.paused then
      _gameRef.paused = true
    end
  else
    -- Al recuperar foco, mantener la pausa que ya estaba
    -- (el usuario puede reanudar manualmente con Escape/P)
    if _gameRef.state == "playing" and _wasPaused then
      -- No forzar unpause para evitar sorpresas al jugador
    end
  end
end

--- Maneja cambios de visibilidad (útil en móviles).
-- Al ocultarse: pausa el juego si estaba jugando.
-- @param visible true si la app se hizo visible, false si se ocultó
function Lifecycle.onVisible(visible)
  if not visible and _gameRef and _gameRef.state == "playing" then
    if not _gameRef.paused then
      _gameRef.paused = true
      _wasPaused = false  -- Resetear porque es pausa automática
    end
  end
end

-- ═══════════════════════════════════════════════════════
-- CIERRE
-- ═══════════════════════════════════════════════════════

--- Maneja el cierre de la aplicación.
-- Guarda todos los datos pendientes antes de salir.
function Lifecycle.quit()
  if _gameRef and _gameRef.player then
    local CurrencyManager = require("src.managers.currency_manager")
    local SettingsManager = require("src.managers.settings_manager")
    CurrencyManager.save()
    SettingsManager.save()
  end
end

-- ═══════════════════════════════════════════════════════
-- MEMORIA
-- ═══════════════════════════════════════════════════════

--- Maneja señales de memoria baja.
-- Fuerza garbage collection para liberar memoria.
function Lifecycle.onLowMemory()
  collectgarbage()
  collectgarbage()
end

-- ═══════════════════════════════════════════════════════
-- EXTENSIBILIDAD
-- ═══════════════════════════════════════════════════════

--- Registra un callback personalizado para eventos de lifecycle.
-- @param key Identificador único del callback
-- @param fn Función a ejecutar cuando se dispare el evento
function Lifecycle.register(key, fn)
  _callbacks[key] = fn
end

--- Obtiene el estado de pausa antes de perder foco.
-- @return true si el juego estaba pausado antes de perder foco
function Lifecycle.getPauseState()
  return _wasPaused
end

return Lifecycle
