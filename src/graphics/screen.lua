-- screen.lua
-- Sistema de viewport virtual con escalado uniforme y letterbox.
-- Renderiza a resolución fija (700×400) y escala a cualquier tamaño de ventana.
-- Maneja: escalado, offset, transformación de input, fuentes, letterbox.
-- Todos los módulos usan Screen.getWidth/Height en lugar de love.graphics.

local Screen = {}

-- ═══════════════════════════════════════════════════════
-- CONFIGURACIÓN DE DISEÑO
-- ═══════════════════════════════════════════════════════

local DESIGN_W = 700   -- Ancho virtual de diseño
local DESIGN_H = 400   -- Alto virtual de diseño
local DESIGN_ASPECT = DESIGN_W / DESIGN_H

-- ═══════════════════════════════════════════════════════
-- ESTADO INTERNO
-- ═══════════════════════════════════════════════════════

local scale = 1        -- Factor de escalado actual
local invScale = 1     -- Inverso del escalado (para input transform)
local offsetX = 0      -- Offset X de letterbox
local offsetY = 0      -- Offset Y de letterbox
local screenW = DESIGN_W   -- Ancho virtual (siempre DESIGN_W)
local screenH = DESIGN_H   -- Alto virtual (siempre DESIGN_H)
local fullscreenW = DESIGN_W  -- Ancho real de ventana
local fullscreenH = DESIGN_H  -- Alto real de ventana

-- ═══════════════════════════════════════════════════════
-- INICIALIZACIÓN
-- ═══════════════════════════════════════════════════════

--- Inicializa el sistema de pantalla.
-- Llama a update() para calcular escalado inicial.
function Screen.init()
  Screen.update()
end

--- Recalcula escalado y offsets basándose en el tamaño actual de la ventana.
-- Se llama en init() y en love.resize().
-- Calcula letterbox: mantiene aspect ratio, centra el contenido.
function Screen.update()
  fullscreenW = love.graphics.getWidth()
  fullscreenH = love.graphics.getHeight()
  local windowAspect = fullscreenW / fullscreenH
  if windowAspect > DESIGN_ASPECT then
    -- Ventana más ancha que el diseño: letterbox horizontal
    scale = fullscreenH / DESIGN_H
    offsetX = math.floor((fullscreenW - DESIGN_W * scale) / 2)
    offsetY = 0
  else
    -- Ventana más alta que el diseño: letterbox vertical
    scale = fullscreenW / DESIGN_W
    offsetX = 0
    offsetY = math.floor((fullscreenH - DESIGN_H * scale) / 2)
  end
  invScale = 1 / scale
  screenW = DESIGN_W
  screenH = DESIGN_H
end

-- ═══════════════════════════════════════════════════════
-- CONSULTAS
-- ═══════════════════════════════════════════════════════

--- Ancho virtual del viewport (siempre DESIGN_W).
function Screen.getWidth()  return screenW end

--- Alto virtual del viewport (siempre DESIGN_H).
function Screen.getHeight() return screenH end

--- Ancho de diseño original.
function Screen.getDesignWidth()  return DESIGN_W end

--- Alto de diseño original.
function Screen.getDesignHeight() return DESIGN_H end

--- Factor de escalado actual.
function Screen.getScale() return scale end

--- Offsets de letterbox (offsetX, offsetY).
function Screen.getOffsets() return offsetX, offsetY end

-- ═══════════════════════════════════════════════════════
-- TRANSFORMACIÓN DE COORDENADAS
-- ═══════════════════════════════════════════════════════

--- Convierte coordenadas de pantalla a coordenadas virtuales.
-- Usado para transformar input de touch/mouse.
-- @param sx Coordenada X de pantalla
-- @param sy Coordenada Y de pantalla
-- @return vx, vy Coordenadas virtuales
function Screen.toVirtual(sx, sy)
  return (sx - offsetX) * invScale, (sy - offsetY) * invScale
end

--- Convierte coordenadas virtuales a coordenadas de pantalla.
-- @param vx Coordenada X virtual
-- @param vy Coordenada Y virtual
-- @return sx, sy Coordenadas de pantalla
function Screen.toScreen(vx, vy)
  return vx * scale + offsetX, vy * scale + offsetY
end

-- ═══════════════════════════════════════════════════════
-- RENDERIZADO
-- ═══════════════════════════════════════════════════════

--- Aplica el transform de viewport (push + translate + scale).
-- Llamar antes de dibujar contenido del juego.
function Screen.apply()
  love.graphics.push()
  love.graphics.translate(offsetX, offsetY)
  love.graphics.scale(scale)
end

--- Restaura el transform anterior (pop).
-- Llamar después de dibujar contenido del juego.
function Screen.clear()
  love.graphics.pop()
end

--- Calcula tamaño de fuente proporcional al viewport.
-- @param base Tamaño base de la fuente
-- @return Tamaño escalado
function Screen.fontSize(base)
  return math.max(6, math.floor(base * scale * 0.5 + base * 0.5))
end

--- Dibuja las barras de letterbox (áreas negras).
-- Se dibuja ANTES de Screen.apply() para llenar los bordes.
function Screen.drawLetterbox()
  local r, g, b, a = love.graphics.getBackgroundColor()
  love.graphics.setColor(r, g, b, a or 1)
  if offsetX > 0 then
    love.graphics.rectangle("fill", 0, 0, offsetX, fullscreenH)
    love.graphics.rectangle("fill", fullscreenW - offsetX, 0, offsetX, fullscreenH)
  end
  if offsetY > 0 then
    love.graphics.rectangle("fill", 0, 0, fullscreenW, offsetY)
    love.graphics.rectangle("fill", 0, fullscreenH - offsetY, fullscreenW, offsetY)
  end
  love.graphics.setColor(1, 1, 1, 1)
end

return Screen
