local floor = math.floor
local lg = love.graphics
local lw = lg.getWidth
local lh = lg.getHeight

local Customize = {}

local function getLayout()
  local w, h = lw(), lh()
  local isLandscape = w > h
  local cols, cardW, cardH, spacingX, spacingY

  if isLandscape then
    cols = 6
    cardW = 90
    cardH = 100
    spacingX = 8
    spacingY = 8
  else
    cols = 3
    cardW = 108
    cardH = 115
    spacingX = 10
    spacingY = 10
  end

  local totalW = cols * cardW + (cols - 1) * spacingX
  local startX = (w - totalW) / 2
  local startY = isLandscape and 50 or 80
  return cols, cardW, cardH, spacingX, spacingY, startX, startY
end

function Customize.draw(g)
  local w, h = lw(), lh()
  local ShipDesigns = require("src.ship_designs")

  lg.setFont(g.bigFont)
  local title = "CHOOSE YOUR SHIP"
  lg.setColor(0.3, 0.8, 1, 1)
  lg.print(title, w / 2 - g.bigFont:getWidth(title) / 2, 20)

  lg.setFont(g.smallFont)
  lg.setColor(1, 1, 1, 0.5)
  local subtitle = "Customize your ship before playing"
  lg.print(subtitle, w / 2 - g.smallFont:getWidth(subtitle) / 2, 52)

  local cols, cardW, cardH, spacingX, spacingY, startX, startY = getLayout()
  local designCount = ShipDesigns.count()

  for i = 1, designCount do
    local design = ShipDesigns.get(i)
    local col = (i - 1) % cols
    local row = floor((i - 1) / cols)
    local cardX = startX + col * (cardW + spacingX)
    local cardY = startY + row * (cardH + spacingY)
    local isSelected = (i == g.selectedDesign)

    if isSelected then
      lg.setColor(0.3, 0.8, 1, 0.3)
      lg.rectangle("fill", cardX - 3, cardY - 3, cardW + 6, cardH + 6, 10, 10)
    end

    lg.setColor(0.1, 0.1, 0.15, 0.9)
    lg.rectangle("fill", cardX, cardY, cardW, cardH, 8, 8)

    lg.setColor(design.color[1], design.color[2], design.color[3], 0.3)
    lg.rectangle("line", cardX, cardY, cardW, cardH, 8, 8)

    local previewX = cardX + cardW / 2
    local previewY = cardY + 38
    local verts = {}
    for v = 1, #design.verts, 2 do
      verts[#verts + 1] = previewX + design.verts[v]
      verts[#verts + 1] = previewY + design.verts[v + 1]
    end

    lg.setColor(design.color[1] * 0.4, design.color[2] * 0.4, design.color[3] * 0.4, 1)
    lg.polygon("fill", verts)
    lg.setColor(design.accent[1], design.accent[2], design.accent[3], 1)
    lg.setLineWidth(2)
    lg.polygon("line", verts)

    lg.setColor(design.engineColor[1], design.engineColor[2], design.engineColor[3], 0.6)
    lg.polygon("fill", previewX - 3, previewY + 14, previewX, previewY + 24, previewX + 3, previewY + 14)

    lg.setFont(g.smallFont)
    lg.setColor(1, 1, 1, 0.9)
    lg.print(design.name, previewX - g.smallFont:getWidth(design.name) / 2, cardY + 65)

    lg.setColor(1, 1, 1, 0.4)
    lg.print(design.desc, previewX - g.smallFont:getWidth(design.desc) / 2, cardY + 82)

    if isSelected then
      lg.setColor(0.3, 1, 0.6, 0.8)
      lg.print("SELECTED", previewX - g.smallFont:getWidth("SELECTED") / 2, cardY + 98)
    end
  end

  local btnY = h - 60
  lg.setColor(0.2, 0.7, 0.4, 0.8)
  lg.rectangle("fill", w / 2 - 80, btnY, 160, 40, 8, 8)
  lg.setColor(1, 1, 1, 0.9)
  lg.setFont(g.font)
  lg.print("PLAY", w / 2 - g.font:getWidth("PLAY") / 2, btnY + 10)

  lg.setColor(1, 1, 1, 0.3)
  lg.setFont(g.smallFont)
  local hint = "Tap a ship to select it"
  lg.print(hint, w / 2 - g.smallFont:getWidth(hint) / 2, h - 18)
end

function Customize.handleInput(g)
  if not g.input:isFire() then return end

  local w, h = lw(), lh()
  local tx, ty = love.mouse.getPosition()
  if not tx or tx == 0 then return end

  local ShipDesigns = require("src.ship_designs")
  local cols, cardW, cardH, spacingX, spacingY, startX, startY = getLayout()
  local designCount = ShipDesigns.count()

  for i = 1, designCount do
    local col = (i - 1) % cols
    local row = floor((i - 1) / cols)
    local cardX = startX + col * (cardW + spacingX)
    local cardY = startY + row * (cardH + spacingY)
    if tx >= cardX and tx <= cardX + cardW and ty >= cardY and ty <= cardY + cardH then
      g.selectedDesign = i
      return
    end
  end

  local btnY = h - 60
  if ty >= btnY and ty <= btnY + 40 and tx >= w / 2 - 80 and tx <= w / 2 + 80 then
    g:initRun()
    local State = require("src.state")
    State.reset(g)
  end
end

return Customize
