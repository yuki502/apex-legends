-- entity_pool.lua
-- Object pool genérico para reutilizar entidades y reducir garbage collection.
-- Al obtener una entidad del pool, se reutiliza en lugar de crear una nueva.
-- Al eliminar, la entidad se devuelve al pool para reuso futuro.
-- Ideal para bullets, enemies, powerups y otros objetos de corta vida.

local EntityPool = {}
EntityPool.__index = EntityPool

-- ═══════════════════════════════════════════════════════
-- CONSTRUCTOR
-- ═══════════════════════════════════════════════════════

--- Crea un nuevo object pool.
-- @param allocFn Función para crear nuevas instancias: function(...)
-- @param resetFn Para resetear una instancia reutilizada: function(obj, ...)
-- @param initialSize Número de instancias a pre-allocar (default: 0)
-- @return Nueva instancia de EntityPool
function EntityPool:new(allocFn, resetFn, initialSize)
  local self = setmetatable({}, EntityPool)
  self._pool = {}          -- Entidades disponibles para reuso
  self._active = {}        -- Entidades actualmente en uso
  self._count = 0          -- Número de entidades activas
  self._alloc = allocFn or function() return {} end
  self._reset = resetFn or function() end
  self._initialSize = initialSize or 0

  -- Pre-allocar entidades iniciales si se especifica
  for i = 1, self._initialSize do
    self._pool[#self._pool + 1] = self._alloc()
  end

  return self
end

-- ═══════════════════════════════════════════════════════
-- OBTENER / LIBERAR
-- ═══════════════════════════════════════════════════════

--- Obtiene una entidad del pool o crea una nueva.
-- Si hay entidades disponibles en el pool, reutiliza la última.
-- Si no, crea una nueva con allocFn.
-- @param ... Argumentos para resetFn al reutilizar, o allocFn al crear
-- @return entity, index - La entidad obtenida y su índice en _active
function EntityPool:get(...)
  local obj
  if #self._pool > 0 then
    -- Reutilizar la última entidad del pool
    obj = table.remove(self._pool)
    self._reset(obj, ...)
  else
    -- Crear nueva instancia
    obj = self._alloc(...)
  end
  self._count = self._count + 1
  self._active[self._count] = obj
  return obj, self._count
end

--- Elimina una entidad por índice (swap-remove pattern).
-- Mueve la última entidad activa al índice eliminado para evitar huecos.
-- La entidad eliminada se devuelve al pool.
-- @param index Índice de la entidad a eliminar
function EntityPool:remove(index)
  local last = self._active[self._count]
  self._active[index] = last
  self._active[self._count] = nil
  self._count = self._count - 1
  self._pool[#self._pool + 1] = last
end

--- Libera una entidad específica por referencia.
-- Busca la entidad en _active y la elimina.
-- @param obj Entidad a liberar
-- @return true si se encontró y liberó, false si no estaba activa
function EntityPool:release(obj)
  for i = 1, self._count do
    if self._active[i] == obj then
      self:remove(i)
      return true
    end
  end
  -- Si no estaba activa, agregarla al pool directamente
  self._pool[#self._pool + 1] = obj
  return false
end

-- ═══════════════════════════════════════════════════════
-- ITERACIÓN / CONSULTA
-- ═══════════════════════════════════════════════════════

--- Retorna un iterador para recorrer todas las entidades activas.
-- Uso: for i, entity in pool:each() do ... end
-- @return Función iteradora (ipairs sobre _active)
function EntityPool:each()
  return ipairs(self._active)
end

--- Obtiene la lista de entidades activas y su cantidad.
-- @return _active table, _count number
function EntityPool:getActive()
  return self._active, self._count
end

--- Obtiene el número de entidades activas.
-- @return Número de entidades en uso
function EntityPool:getCount()
  return self._count
end

--- Obtiene una entidad por índice.
-- @param index Índice (1-based)
-- @return Entidad en esa posición, o nil
function EntityPool:get(index)
  return self._active[index]
end

-- ═══════════════════════════════════════════════════════
-- LIMPIEZA
-- ═══════════════════════════════════════════════════════

--- Devuelve todas las entidades activas al pool.
-- No libera memoria, solo mueve referencias.
function EntityPool:clear()
  for i = 1, self._count do
    self._pool[#self._pool + 1] = self._active[i]
  end
  self._active = {}
  self._count = 0
end

--- Retorna el número total de entidades (activas + en pool).
-- @return Tamaño total
function EntityPool:size()
  return self._count
end

return EntityPool
