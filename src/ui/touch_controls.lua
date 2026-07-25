-- touch_controls.lua
-- Controles touch: joystick virtual, botón de disparo, items.
-- Se muestra solo durante el juego (no en menús/hangar/shop).
-- Soporta handedness (mano izquierda/derecha) desde settings.
-- Escalado proporcional al tamaño de pantalla.

local Screen = require("src.graphics.screen")
local lg = love.graphics
local lw = Screen.getWidth
local lh = Screen.getHeight
local sin = math.sin

local ConsumableManager = require("src.managers.consumable_manager")

local TouchControls = {}

local _btnScale = 1

function TouchControls.draw(g)
  if g.state == "hangar" or g.state == "shop" or g.state == "customize" then return end
  local w, h = lw(), lh()
  local touchActive = g.input:isTouchActive()
  local ox, oy = g.input:getTouchOrigin()
  local leftHand = g.leftHanded

  local moveX = leftHand and (w - 70) or 70
  local moveY = h - 80
  local fireX = leftHand and 70 or (w - 70)
  local fireY = h / 2
  local fireR = 38

  g.fireBtn.x = fireX
  g.fireBtn.y = fireY
  g.fireBtn.radius = fireR

  lg.setColor(1, 1, 1, 0.06)
  lg.circle("fill", moveX, moveY, 60)
  lg.setColor(1, 1, 1, 0.12)
  lg.setLineWidth(2)
  lg.circle("line", moveX, moveY, 60)

  if touchActive then
    local dx, dy = g.input:getMovement()
    local knobX = moveX + dx * 55
    local knobY = moveY + dy * 55
    lg.setColor(1, 1, 1, 0.25)
    lg.circle("fill", knobX, knobY, 18)
    lg.setColor(1, 1, 1, 0.35)
    lg.setLineWidth(1.5)
    lg.circle("line", knobX, knobY, 18)
  else
    lg.setColor(1, 1, 1, 0.12)
    lg.circle("fill", moveX, moveY, 18)
  end

  local fireDown = g.input.fireTouchActive
  local pulse = fireDown and 0.9 or (0.65 + sin(g.menuTimer * 3) * 0.15)

  lg.setColor(1, 0.25, 0.25, 0.10)
  lg.circle("fill", fireX, fireY, fireR + 10)
  lg.setColor(1, 0.25, 0.25, 0.18)
  lg.setLineWidth(1)
  lg.circle("line", fireX, fireY, fireR + 10)

  local fillAlpha = fireDown and 0.45 or 0.25
  lg.setColor(1, 0.3, 0.3, fillAlpha)
  lg.circle("fill", fireX, fireY, fireR)
  lg.setColor(1, 0.4, 0.4, pulse)
  lg.setLineWidth(2)
  lg.circle("line", fireX, fireY, fireR)

  lg.setColor(1, 0.3, 0.3, 0.06)
  lg.line(fireX - fireR * 0.5, fireY, fireX + fireR * 0.5, fireY)
  lg.line(fireX, fireY - fireR * 0.5, fireX, fireY + fireR * 0.5)

  local fireAlpha = fireDown and 1.0 or 0.65
  lg.setColor(1, 1, 1, fireAlpha)
  lg.setFont(g.font)
  lg.print("FIRE", fireX - g.font:getWidth("FIRE") / 2, fireY - 9)

  local items = ConsumableManager.getActiveItems()
  local itemR = 16
  local itemSpacing = itemR * 2 + 8
  local itemCount = #items
  if itemCount > 0 then
    local startY = fireY + fireR + 20
    for i = 1, math.min(itemCount, 4) do
      local item = items[i]
      local ix = fireX
      local iy = startY + (i - 1) * itemSpacing

      lg.setColor(item.color[1], item.color[2], item.color[3], 0.2)
      lg.circle("fill", ix, iy, itemR + 4)
      lg.setColor(item.color[1], item.color[2], item.color[3], 0.5)
      lg.setLineWidth(1.5)
      lg.circle("line", ix, iy, itemR)
      lg.setColor(item.color[1], item.color[2], item.color[3], 0.35)
      lg.circle("fill", ix, iy, itemR)

      lg.setColor(1, 1, 1, 0.9)
      lg.setFont(g.tinyFont)
      lg.print(item.icon, ix - g.tinyFont:getWidth(item.icon) / 2, iy - 5)

      lg.setColor(1, 1, 1, 0.7)
      lg.print(tostring(item.stock), ix + itemR - 4, iy - 8)

      g.itemBtns = g.itemBtns or {}
      g.itemBtns[i] = {x = ix, y = iy, r = itemR, key = item.key}
    end
    for i = itemCount + 1, #g.itemBtns do
      g.itemBtns[i] = nil
    end
  else
    g.itemBtns = {}
  end
end

return TouchControls
