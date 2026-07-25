-- logger.lua
-- Sistema de logging con rotación de archivos y niveles de severidad.
-- Registra errores, advertencias, información y debug en archivos timestamps.
-- Soporta buffer con flush automático para evitar I/O per-frame.
-- Los archivos de log se guardan en logs/ con rotación (max 5 archivos, 256KB cada uno).

local Logger = {}
Logger.__index = Logger

-- ═══════════════════════════════════════════════════════
-- NIVELES DE LOG
-- ═══════════════════════════════════════════════════════

local levels = {
  DEBUG = 1,  -- Información detallada para debugging
  INFO = 2,  -- Información general del juego
  WARN = 3,  -- Advertencias que no detienen el juego
  ERROR = 4, -- Errores que podrían causar problemas
}

local levelNames = {[1]="DEBUG", [2]="INFO", [3]="WARN", [4]="ERROR"}

-- ═══════════════════════════════════════════════════════
-- CONFIGURACIÓN
-- ═══════════════════════════════════════════════════════

local MAX_LOG_SIZE = 256 * 1024  -- Tamaño máximo por archivo (256KB)
local MAX_LOG_FILES = 5          -- Máximo de archivos de log antes de rotar
local LOG_DIR = "logs"           -- Directorio de logs (dentro de love.filesystem)

-- ═══════════════════════════════════════════════════════
-- INSTANCIA SINGLETON
-- ═══════════════════════════════════════════════════════

local _instance = nil

-- ═══════════════════════════════════════════════════════
-- CONSTRUCTOR
-- ═══════════════════════════════════════════════════════

--- Crea una nueva instancia del logger.
-- @param opts Tabla de opciones: {minLevel, toFile, toConsole}
-- @return Nueva instancia de Logger
function Logger:new(opts)
  opts = opts or {}
  local self = setmetatable({}, Logger)
  self.minLevel = opts.minLevel or levels.INFO
  self.toFile = opts.toFile or false       -- Habilitar escritura a archivo
  self.toConsole = opts.toConsole or true  -- Habilitar salida a consola
  self.buffer = {}                          -- Buffer de líneas pendientes
  self.bufferSize = 0                       -- Tamaño actual del buffer en bytes
  self.currentFile = nil                    -- Ruta del archivo de sesión actual
  self.fileHandle = nil                     -- Handle del archivo (no usado directamente)
  self.enabled = true                       -- Toggle global del logger
  return self
end

-- ═══════════════════════════════════════════════════════
-- SESIONES
-- ═══════════════════════════════════════════════════════

--- Inicia una nueva sesión de logging.
-- Crea el directorio logs/ si no existe, rota archivos antiguos,
-- y escribe el encabezado de sesión con timestamp.
function Logger:startSession()
  if not self.toFile then return end

  -- Crear directorio de logs si no existe
  local ok = pcall(love.filesystem.createDirectory, LOG_DIR)
  if not ok then
    self.toFile = false
    return
  end

  -- Rotar archivos antiguos antes de crear uno nuevo
  self:rotateLogs()

  -- Crear archivo con timestamp
  local timestamp = os.date("%Y%m%d_%H%M%S")
  local path = LOG_DIR .. "/session_" .. timestamp .. ".log"
  self.currentFile = path

  -- Escribir encabezado de sesión
  self:write('==============================================')
  self:write('Session started: ' .. os.date("%Y-%m-%d %H:%M:%S"))
  self:write('LÖVE ' .. love.getVersion())
  self:write('==============================================')
end

--- Rota los archivos de log eliminando los más antiguos.
-- Mantiene solo MAX_LOG_FILES archivos.
function Logger:rotateLogs()
  local files = {}
  local ok, list = pcall(love.filesystem.getDirectoryItems, LOG_DIR)
  if ok then
    for _, name in ipairs(list) do
      if name:match("^session_.*%.log$") then
        local info = love.filesystem.getInfo(LOG_DIR .. "/" .. name)
        if info then
          table.insert(files, {name = name, modtime = info.modtime})
        end
      end
    end
  end

  -- Ordenar por tiempo de modificación (más viejo primero)
  table.sort(files, function(a, b) return a.modtime < b.modtime end)

  -- Eliminar archivos más viejos si excedemos el límite
  while #files >= MAX_LOG_FILES do
    local oldest = table.remove(files, 1)
    pcall(love.filesystem.remove, LOG_DIR .. "/" .. oldest.name)
  end
end

--- Finaliza la sesión actual y escribe el pie de sesión.
function Logger:endSession()
  self:write('==============================================')
  self:write('Session ended: ' .. os.date("%Y-%m-%d %H:%M:%S"))
  self:write('==============================================')

  if self.toFile then
    self:flush()
    -- Forzar escritura del footer
    love.filesystem.append(self.currentFile, '')
  end
end

-- ═══════════════════════════════════════════════════════
-- NIVELES
-- ═══════════════════════════════════════════════════════

--- Establece el nivel mínimo de logging.
-- @param level Nivel: "DEBUG", "INFO", "WARN", "ERROR" o número 1-4
function Logger:setLevel(level)
  for name, val in pairs(levels) do
    if name == level or val == level then
      self.minLevel = val
      return
    end
  end
end

-- ═══════════════════════════════════════════════════════
-- ESCRITURA
-- ═══════════════════════════════════════════════════════

--- Registra un mensaje con el nivel especificado.
-- El mensaje se formatea con string.format si se proveen argumentos.
-- @param level Nivel de severidad (1-4)
-- @param message Mensaje con formato opcional (ej: "HP: %d")
-- @param ... Argumentos para string.format
function Logger:log(level, message, ...)
  if not self.enabled then return end
  if level < self.minLevel then return end

  local levelStr = levelNames[level] or "UNKNOWN"
  local timestamp = os.date("%H:%M:%S")
  local msg = string.format(message, ...)
  local line = string.format("[%s] %s %s", timestamp, levelStr, msg)

  -- Salida a consola
  if self.toConsole then
    print(line)
  end

  -- Salida a archivo (con buffer)
  if self.toFile then
    self.buffer[#self.buffer + 1] = line
    self.bufferSize = self.bufferSize + #line + 1
    -- Flush automático cuando el buffer excede 4KB
    if self.bufferSize >= 4096 then
      self:flush()
    end
  end
end

--- Vacía el buffer al archivo.
-- Si el archivo excede MAX_LOG_SIZE, rota a uno nuevo.
function Logger:flush()
  if not self.toFile or #self.buffer == 0 then return end

  local content = table.concat(self.buffer, "\n") .. "\n"

  -- Verificar tamaño del archivo actual
  local ok, currentSize = pcall(love.filesystem.getSize, self.currentFile or "")
  if ok and currentSize and (currentSize or 0) + #content > MAX_LOG_SIZE then
    self:write("--- Log truncated (max size reached) ---")
    self:rotateLogs()
    -- Crear nuevo archivo
    local timestamp = os.date("%Y%m%d_%H%M%S")
    local path = LOG_DIR .. "/session_" .. timestamp .. ".log"
    self.currentFile = path
    love.filesystem.write(self.currentFile, content)
  else
    love.filesystem.append(self.currentFile or "logs/fallback.log", content)
  end

  -- Limpiar buffer
  self.buffer = {}
  self.bufferSize = 0
end

--- Escribe una línea directamente al archivo (sin buffer).
-- @param line Línea a escribir
function Logger:write(line)
  if not self.toFile then return end
  local content = line .. "\n"
  love.filesystem.append(self.currentFile or "logs/fallback.log", content)
end

-- ═══════════════════════════════════════════════════════
-- MÉTODOS DE CONVENIENCIA
-- ═══════════════════════════════════════════════════════

--- Log de nivel DEBUG (solo aparece con minLevel ≤ 1).
function Logger:debug(message, ...) self:log(levels.DEBUG, message, ...) end

--- Log de nivel INFO (nivel por defecto).
function Logger:info(message, ...)  self:log(levels.INFO, message, ...) end

--- Log de nivel WARN (advertencias).
function Logger:warn(message, ...)  self:log(levels.WARN, message, ...) end

--- Log de nivel ERROR (errores críticos).
function Logger:error(message, ...) self:log(levels.ERROR, message, ...) end

-- ═══════════════════════════════════════════════════════
-- SINGLETON
-- ═══════════════════════════════════════════════════════

--- Obtiene la instancia singleton del logger.
-- Crea una instancia por defecto si no existe.
-- @return Instancia de Logger
function Logger:getInstance()
  if not _instance then
    _instance = Logger:new({
      minLevel = levels.INFO,
      toFile = false,
      toConsole = true,
    })
  end
  return _instance
end

--- Configura la instancia singleton.
-- @param opts Tabla con opciones: {minLevel, toFile, toConsole}
function Logger.configure(opts)
  if _instance then
    _instance.minLevel = opts.minLevel or _instance.minLevel
    _instance.toFile = opts.toFile or _instance.toFile
    _instance.toConsole = (opts.toConsole ~= false)
  end
end

-- Exponer niveles para uso externo
Logger.levels = levels

return Logger
