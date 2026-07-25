-- settings_manager.lua
-- Gestión de configuración del jugador con persistencia.
-- Guarda/carga settings en settings.dat (formato key=value por línea).
-- Soporta: volumen música/SFX, handedness, devMode, logToFile.
-- Idempotente: init() solo carga una vez (seguro llamar múltiples veces).

local SettingsManager = {}

-- ═══════════════════════════════════════════════════════
-- VALORES POR DEFECTO
-- ═══════════════════════════════════════════════════════

local _defaults = {
  musicVol = 0.7,    -- Volumen de música (0.0 - 1.0)
  sfxVol = 0.8,      -- Volumen de efectos de sonido (0.0 - 1.0)
  handedness = "right", -- Mano dominante para controles touch
  devMode = false,   -- Modo desarrollador (overlay, hitboxes, etc.)
  logToFile = false, -- Guardar logs en archivos
}

-- ═══════════════════════════════════════════════════════
-- ESTADO INTERNO
-- ═══════════════════════════════════════════════════════

local _data = {}     -- Datos actuales (mezcla de defaults + guardados)
local _loaded = false -- Si ya se cargó (idempotencia)

-- ═══════════════════════════════════════════════════════
-- INICIALIZACIÓN
-- ═══════════════════════════════════════════════════════

--- Inicializa el gestor de configuración.
-- Idempotente: si ya se cargó, no hace nada.
-- Seguro llamar múltiples veces (ej: love.load y loading tasks).
function SettingsManager.init()
  if _loaded then return end
  SettingsManager.load()
  _loaded = true
end

-- ═══════════════════════════════════════════════════════
-- CARGA / GUARDADO
-- ═══════════════════════════════════════════════════════

--- Carga la configuración desde settings.dat.
-- Primero aplica defaults, luego sobreescribe con valores guardados.
-- Formato del archivo: key=value por línea (ej: "musicVol=0.7").
function SettingsManager.load()
  -- Aplicar valores por defecto
  for k, v in pairs(_defaults) do
    _data[k] = v
  end

  -- Leer archivo de configuración
  local ok, content = pcall(love.filesystem.read, "settings.dat")
  if ok and content then
    for line in content:gmatch("[^\n]+") do
      local k, v = line:match("^([^=]+)=(.+)$")
      if k and v and _defaults[k] ~= nil then
        -- Parsear valor: número o string especial
        local num = tonumber(v)
        if num then
          _data[k] = num
        elseif v == "left" or v == "right" then
          _data[k] = v
        end
      end
    end
  end
end

--- Guarda la configuración actual a settings.dat.
-- Formato: key=value por línea, separado por newlines.
function SettingsManager.save()
  local lines = {}
  for k, v in pairs(_data) do
    lines[#lines + 1] = k .. "=" .. tostring(v)
  end
  pcall(love.filesystem.write, "settings.dat", table.concat(lines, "\n"))
end

-- ═══════════════════════════════════════════════════════
-- ACCESO GENÉRICO
-- ═══════════════════════════════════════════════════════

--- Obtiene un valor de configuración.
-- @param key Nombre de la clave
-- @return Valor actual
function SettingsManager.get(key)
  return _data[key]
end

--- Establece un valor de configuración y guarda automáticamente.
-- @param key Nombre de la clave
-- @param value Nuevo valor
function SettingsManager.set(key, value)
  _data[key] = value
  SettingsManager.save()
end

-- ═══════════════════════════════════════════════════════
-- VOLUMEN
-- ═══════════════════════════════════════════════════════

--- Obtiene el volumen de la música.
-- @return Volumen (0.0 - 1.0)
function SettingsManager.getMusicVol()
  return _data.musicVol
end

--- Obtiene el volumen de efectos de sonido.
-- @return Volumen (0.0 - 1.0)
function SettingsManager.getSfxVol()
  return _data.sfxVol
end

--- Establece el volumen de la música (clamped 0.0 - 1.0).
function SettingsManager.setMusicVol(v)
  _data.musicVol = math.max(0, math.min(1, v))
  SettingsManager.save()
end

--- Establece el volumen de efectos de sonido (clamped 0.0 - 1.0).
function SettingsManager.setSfxVol(v)
  _data.sfxVol = math.max(0, math.min(1, v))
  SettingsManager.save()
end

-- ═══════════════════════════════════════════════════════
-- HANDEDNESS (MANOS)
-- ═══════════════════════════════════════════════════════

--- Verifica si el jugador es zurdo.
-- @return true si handedness es "left"
function SettingsManager.isLeftHanded()
  return _data.handedness == "left"
end

--- Establece la handedness del jugador.
-- @param h "left" o "right"
function SettingsManager.setHandedness(h)
  _data.handedness = h
  SettingsManager.save()
end

--- Alterna la handedness entre "left" y "right".
function SettingsManager.toggleHandedness()
  _data.handedness = _data.handedness == "right" and "left" or "right"
  SettingsManager.save()
end

-- ═══════════════════════════════════════════════════════
-- MODO DESARROLLADOR
-- ═══════════════════════════════════════════════════════

--- Verifica si el modo desarrollador está habilitado.
-- @return true si devMode está activo
function SettingsManager.isDevMode()
  return _data.devMode == true
end

--- Habilita o deshabilita el modo desarrollador.
-- @param v true para activar, false para desactivar
function SettingsManager.setDevMode(v)
  _data.devMode = v == true
  SettingsManager.save()
end

-- ═══════════════════════════════════════════════════════
-- LOGGING
-- ═══════════════════════════════════════════════════════

--- Verifica si el logging a archivo está habilitado.
-- @return true si logToFile está activo
function SettingsManager.isLogToFile()
  return _data.logToFile == true
end

--- Habilita o deshabilita el logging a archivo.
-- @param v true para activar, false para desactivar
function SettingsManager.setLogToFile(v)
  _data.logToFile = v == true
  SettingsManager.save()
end

return SettingsManager
