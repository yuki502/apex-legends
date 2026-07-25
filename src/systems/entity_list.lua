-- entity_list.lua
-- Lista genérica de entidades con swap-remove pattern eficiente.
-- Mantiene un array contiguo sin huecos para iteración rápida.
-- Al eliminar, mueve la última entidad al hueco para O(1) eliminación.
-- API compatible con arrays planos: items[i], count, etc.

local EntityList = {}
EntityList.__index = EntityList

-- ═══════════════════════════════════════════════════════
-- CONSTRUCTOR
-- ═══════════════════════════════════════════════════════

--- Crea una nueva lista de entidades.
-- @param initialSize Tamaño inicial pre-reservado (opcional)
-- @return Nueva instancia de EntityList
function EntityList:new(initialSize)
  local self = setmetatable({}, EntityList)
  self.items = {}    -- Array de entidades (1-indexed)
  self.count = 0     -- Número actual de entidades
  if initialSize and initialSize > 0 then
    self.items = {}
  end
  return self
end

-- ═══════════════════════════════════════════════════════
-- AGREGAR / ELIMINAR
-- ═══════════════════════════════════════════════════════

--- Agrega una entidad al final de la lista.
-- @param obj Entidad a agregar
-- @return La entidad agregada
function EntityList:add(obj)
  self.count = self.count + 1
  self.items[self.count] = obj
  return obj
end

--- Elimina una entidad por índice (swap-remove pattern).
-- Mueve la última entidad al índice eliminado para O(1).
-- ⚠️ IMPORTANTE: El orden de las entidades puede cambiar.
-- @param index Índice de la entidad a eliminar
function EntityList:remove(index)
  local last = self.items[self.count]
  self.items[index] = last
  self.items[self.count] = nil
  self.count = self.count - 1
end

-- ═══════════════════════════════════════════════════════
-- ITERACIÓN
-- ═══════════════════════════════════════════════════════

--- Limpia la lista completa.
-- No libera memoria, solo resetea count.
function EntityList:clear()
  for i = 1, self.count do
    self.items[i] = nil
  end
  self.count = 0
end

--- Retorna un iterador para recorrer todas las entidades.
-- Uso: for i, entity in list:each() do ... end
-- @return Función iteradora
function EntityList:each()
  local i = 1
  return function()
    if i <= self.count then
      local item = self.items[i]
      i = i + 1
      return i - 1, item
    end
  end
end

-- ═══════════════════════════════════════════════════════
-- ACCESO DIRECTO
-- ═══════════════════════════════════════════════════════

--- Obtiene una entidad por índice.
-- @param index Índice (1-based)
-- @return Entidad o nil
function EntityList:get(index)
  return self.items[index]
end

--- Establece una entidad en un índice específico.
-- @param index Índice (1-based)
-- @param value Entidad a放置ar
function EntityList:set(index, value)
  self.items[index] = value
end

--- Retorna el número de entidades en la lista.
-- @return Cantidad de entidades
function EntityList:len()
  return self.count
end

return EntityList
