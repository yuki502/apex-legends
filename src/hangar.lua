local Object = require("lib.classic")
local lume = require("lib.lume")
local flux = require("lib.flux")
local ComponentDefs = require("src.component_defs")

local lg = love.graphics
local lw = lg.getWidth
local lh = lg.getHeight

local Hangar = Object:extend()

local SLOT_RADIUS = 18

function Hangar:new(inventory, effects)
  self.inventory = inventory
  self.effects = effects
  self.tweens = flux.group()
  self.selectedSlot = nil
  self.selectedComponent = nil
  self.dragSlot = nil
  self.dragComp = nil
  self.dragX = 0
  self.dragY = 0
  self.isDragging = false
  self.scrollY = 0
  self.maxScroll = 0
  self.slotHighlight = {}
  self.hoverSlot = nil
  self.hoverComp = nil
  self.showTooltip = false
  self.tooltipItem = nil
  self.stats = inventory:getStats()
  self.synergies = {}
  self.statsDirty = true
  self.installAnim = {}
  self.slotPositions = {}
  self:computeSlotPositions()
end

function Hangar:computeSlotPositions()
  self.slotPositions = {}
  local cx, cy = lw() / 2, lh() / 2
  for slotKey, info in pairs(ComponentDefs.SLOT_LAYOUT) do
    self.slotPositions[slotKey] = {
      x = cx + info.x,
      y = cy + info.y,
      label = info.label,
    }
  end
end

function Hangar:refresh()
  self:computeSlotPositions()
  self.statsDirty = true
end

function Hangar:update(dt)
  self.tweens:update(dt)
  if self.statsDirty then
    self.stats = self.inventory:getStats()
    self.synergies = self.inventory:getActiveSynergies() or {}
    self.statsDirty = false
  end
  -- update install animations
  local i = 1
  while i <= #self.installAnim do
    local a = self.installAnim[i]
    a.progress = a.progress + dt * 3
    if a.progress >= 1 then
      table.remove(self.installAnim, i)
    else
      i = i + 1
    end
  end
end

function Hangar:getSlotAt(x, y)
  for slotKey, pos in pairs(self.slotPositions) do
    local dx = x - pos.x
    local dy = y - pos.y
    if dx * dx + dy * dy <= (SLOT_RADIUS + 4) * (SLOT_RADIUS + 4) then
      return slotKey, pos
    end
  end
  return nil
end

function Hangar:getComponentInListAt(x, y, ox, oy)
  local items = self.inventory:getOwnedList()
  local startY = oy + 40
  local itemH = 36
  local visCount = math.floor((lh() - startY - 20) / itemH)
  for i = 1 + self.scrollY, math.min(#items, self.scrollY + visCount) do
    local item = items[i]
    local iy = startY + (i - 1 - self.scrollY) * itemH
    if x >= ox + 10 and x <= ox + lw() / 2.5 - 10 and y >= iy and y <= iy + itemH then
      return item
    end
  end
  return nil
end

function Hangar:mousepressed(x, y, button)
  if button ~= 1 then return end
  local cx, cy = lw() / 2, lh() / 2

  -- Check if clicking a ship slot
  local slotKey = self:getSlotAt(x, y)
  if slotKey then
    local cat = ComponentDefs.SLOT_CATEGORIES[slotKey]
    if not cat then return end
    local compId, compDef = self.inventory:getSlotInstalled(slotKey)
    if compId then
      -- uninstall
      self.inventory:uninstall(slotKey)
      self.statsDirty = true
      if self.effects then
        local pos = self.slotPositions[slotKey]
        self.effects:installComponent(pos.x, pos.y, compDef.color or {1,1,1})
      end
      self.installAnim[#self.installAnim + 1] = {
        slotKey = slotKey,
        progress = 0,
        fromId = compId,
      }
    end
    return
  end

  -- Check component list
  local panelX = lw() - lw() / 2.5 - 10
  local panelY = 50
  if x >= panelX and x <= lw() - 10 then
    local item = self:getComponentInListAt(x, y, panelX, panelY)
    if item and item.count > 0 then
      self.selectedComponent = item.id
    end
    return
  end

  -- Check install zone (center area) for selected component
  if self.selectedComponent and x >= lw() * 0.2 and x <= lw() * 0.8 and y >= 50 and y <= lh() - 50 then
    local slotKey = self:getSlotAt(x, y)
    if not slotKey then
      -- find nearest matching slot
      local cat = ComponentDefs.ALL[self.selectedComponent].slot
      local bestSlot, bestDist = nil, 999
      for sk, pos in pairs(self.slotPositions) do
        if ComponentDefs.SLOT_CATEGORIES[sk] == cat then
          local dx = x - pos.x
          local dy = y - pos.y
          local d = dx * dx + dy * dy
          if d < bestDist then
            bestDist = d
            bestSlot = sk
          end
        end
      end
      slotKey = bestSlot
    end
    if slotKey then
      local ok, oldId = self.inventory:install(slotKey, self.selectedComponent)
      if ok then
        self.statsDirty = true
        self.selectedComponent = nil
        local pos = self.slotPositions[slotKey]
        local def = ComponentDefs.ALL[self.selectedComponent]
        if self.effects then
          self.effects:installComponent(pos.x, pos.y, def and def.color or {1,1,1})
        end
      end
    end
    return
  end

  -- Clicking stats or synergies, deselect
  self.selectedComponent = nil
end

function Hangar:mousemoved(x, y, dx, dy)
  self.hoverSlot = self:getSlotAt(x, y)
  self.hoverComp = nil

  local panelX = lw() - lw() / 2.5 - 10
  local panelY = 50
  if x >= panelX and x <= lw() - 10 then
    self.hoverComp = self:getComponentInListAt(x, y, panelX, panelY)
  end

  -- scroll for component list
  if love.mouse.isDown(1) and x >= panelX then
    if self._scrollStart == nil then
      self._scrollStart = { y = y, scroll = self.scrollY }
    end
    local dy2 = y - self._scrollStart.y
    self.scrollY = math.max(0, math.min(self.maxScroll, self._scrollStart.scroll - dy2 / 36))
  else
    self._scrollStart = nil
  end
end

function Hangar:mousewheel(y)
  self.scrollY = math.max(0, math.min(self.maxScroll, self.scrollY - y))
end

function Hangar:keypressed(key)
  if key == "escape" then
    self.selectedComponent = nil
    return true
  end
  return false
end

local function drawComponentShape(verts, x, y, size, color, alpha, hollow)
  alpha = alpha or 1
  lg.push()
  lg.translate(x, y)
  lg.setColor(color[1], color[2], color[3], alpha)
  if #verts > 4 then
    if hollow then
      lg.setLineWidth(2)
      lg.polygon("line", verts)
    else
      lg.polygon("fill", verts)
    end
  else
    lg.circle("fill", 0, 0, size or 8)
  end
  lg.pop()
end

function Hangar:draw()
  local w, h = lw(), lh()
  local cx, cy = w / 2, h / 2

  -- title
  lg.setColor(0.8, 0.9, 1, 1)
  lg.print("HANGAR", 20, 10)

  -- back indicator
  lg.setColor(0.5, 0.6, 0.7, 1)
  lg.print("Press ENTER to continue", w - 180, 10)

  -- Draw slots
  for slotKey, pos in pairs(self.slotPositions) do
    local compId, compDef = self.inventory:getSlotInstalled(slotKey)
    local isHover = self.hoverSlot == slotKey
    local isSelected = self.selectedSlot == slotKey
    local cat = ComponentDefs.SLOT_CATEGORIES[slotKey]
    local catColor = ComponentDefs.CATEGORIES[cat] and ComponentDefs.CATEGORIES[cat].color or {1,1,1}

    -- slot background
    local r = SLOT_RADIUS
    if isHover then r = SLOT_RADIUS + 3 end
    if isSelected then r = SLOT_RADIUS + 5 end

    lg.setColor(0.2, 0.25, 0.35, 0.6)
    lg.circle("fill", pos.x, pos.y, r + 2)
    lg.setColor(isHover and 0.5 or 0.3, isHover and 0.6 or 0.35, isHover and 0.8 or 0.45, 0.8)
    lg.circle("line", pos.x, pos.y, r + 2)

    if compId and compDef then
      -- draw installed component
      local color = compDef.rarityColor or compDef.color or {1,1,1}
      drawComponentShape(compDef.visual.verts, pos.x, pos.y, compDef.visual.size, color, 1, compDef.visual.hollow)
      -- rarity indicator
      lg.setColor(color[1], color[2], color[3], 0.6)
      lg.circle("line", pos.x, pos.y, r - 2)
    else
      -- empty slot
      lg.setColor(catColor[1] * 0.3, catColor[2] * 0.3, catColor[3] * 0.3, 0.5)
      lg.circle("line", pos.x, pos.y, r - 4)
    end

    -- slot label
    lg.setColor(0.6, 0.7, 0.8, 0.7)
    lg.print(pos.label, pos.x - 20, pos.y + r + 4)

    -- install animation
    for _, anim in ipairs(self.installAnim) do
      if anim.slotKey == slotKey then
        local p = anim.progress
        lg.setColor(1, 1, 1, 1 - p)
        lg.circle("line", pos.x, pos.y, r * (1 + p), 12)
      end
    end
  end

  -- Draw selected component following mouse if one is selected
  if self.selectedComponent then
    local def = ComponentDefs.ALL[self.selectedComponent]
    if def then
      local mx, my = love.mouse.getPosition()
      lg.setColor(1, 1, 1, 0.5)
      lg.circle("line", mx, my, SLOT_RADIUS + 4)
      drawComponentShape(def.visual.verts, mx, my, def.visual.size, def.rarityColor, 0.7, def.visual.hollow)
    end
  end

  -- Draw component list (right panel)
  local panelX = w - w / 2.5 - 10
  local panelY = 50
  local panelW = w / 2.5
  local panelH = h - panelY - 10

  lg.setColor(0.1, 0.12, 0.18, 0.85)
  lg.rectangle("fill", panelX, panelY, panelW, panelH)
  lg.setColor(0.3, 0.35, 0.5, 0.6)
  lg.rectangle("line", panelX, panelY, panelW, panelH)

  lg.setColor(0.8, 0.9, 1, 1)
  lg.print("COMPONENTS", panelX + 10, panelY + 5)

  local items = self.inventory:getOwnedList()
  local startY = panelY + 25
  local itemH = 36
  local visCount = math.floor((panelH - 35) / itemH)
  self.maxScroll = math.max(0, #items - visCount)

  for i = 1 + self.scrollY, math.min(#items, self.scrollY + visCount) do
    local item = items[i]
    local iy = startY + (i - 1 - self.scrollY) * itemH
    local isHover = self.hoverComp and self.hoverComp.id == item.id
    local isSel = self.selectedComponent == item.id

    if isSel then
      lg.setColor(0.3, 0.4, 0.6, 0.5)
      lg.rectangle("fill", panelX + 4, iy, panelW - 8, itemH - 2)
    elseif isHover then
      lg.setColor(0.2, 0.3, 0.5, 0.3)
      lg.rectangle("fill", panelX + 4, iy, panelW - 8, itemH - 2)
    end

    local def = item.def
    local rc = def.rarityColor
    lg.setColor(rc[1], rc[2], rc[3], 1)

    -- rarity indicator dot
    lg.circle("fill", panelX + 14, iy + itemH / 2, 3)

    -- name
    lg.print(def.name, panelX + 22, iy + 2)

    -- slot label small
    lg.setColor(0.5, 0.6, 0.7, 0.7)
    local cat = ComponentDefs.CATEGORIES[def.slot]
    lg.print(cat and cat.label or def.slot, panelX + 22, iy + 16)

    -- count badge
    if item.count > 1 then
      lg.setColor(1, 1, 1, 0.8)
      lg.print("x" .. item.count, panelX + panelW - 35, iy + itemH / 2 - 6)
    end

    -- rarity label
    lg.setColor(rc[1] * 0.6, rc[2] * 0.6, rc[3] * 0.6, 0.6)
    lg.print(def.rarityLabel, panelX + panelW - 80, iy + 2)
  end

  -- Stats panel (left side)
  local sPanelX = 10
  local sPanelY = 30
  local sPanelW = 150
  local sPanelH = h - 70

  lg.setColor(0.1, 0.12, 0.18, 0.7)
  lg.rectangle("fill", sPanelX, sPanelY, sPanelW, sPanelH)
  lg.setColor(0.3, 0.35, 0.5, 0.4)
  lg.rectangle("line", sPanelX, sPanelY, sPanelW, sPanelH)

  lg.setColor(0.8, 0.9, 1, 1)
  lg.print("SHIP STATS", sPanelX + 5, sPanelY + 2)

  local s = self.stats
  local statLines = {
    {"DMG", string.format("%.1f", s.damage), s.damage > 1 and {0.3,1,0.3} or {1,0.8,0.8}},
    {"FIRE", string.format("%.1f", s.fireRate), s.fireRate > 1 and {0.3,1,0.3} or {1,0.8,0.8}},
    {"SPEED", string.format("%.1f", s.speed), s.speed > 1 and {0.3,1,0.3} or {1,0.8,0.8}},
    {"HP", string.format("%.0f", s.maxHp), s.maxHp >= 100 and {0.3,1,0.3} or {1,0.8,0.8}},
    {"SHIELD", string.format("%.0f", s.shield), s.shield > 0 and {0.3,0.8,1} or {0.5,0.5,0.5}},
    {"CRIT", string.format("%.0f%%", s.critChance * 100), s.critChance > 0 and {1,0.8,0.2} or {0.5,0.5,0.5}},
    {"PROJ", string.format("%.0f", s.projectileCount), s.projectileCount > 1 and {0.3,1,0.8} or {1,0.8,0.8}},
    {"REGEN", string.format("%.1f/s", s.hpRegen), s.hpRegen > 0 and {0.3,1,0.3} or {0.5,0.5,0.5}},
    {"LIFESTEAL", string.format("%.0f%%", s.lifesteal * 100), s.lifesteal > 0 and {1,0.3,0.3} or {0.5,0.5,0.5}},
    {"DODGE", string.format("%.1fs", s.dodgeCooldown), s.dodgeCooldown < 1 and {0.3,1,0.8} or {1,0.8,0.8}},
  }

  for i, line in ipairs(statLines) do
    local y = sPanelY + 22 + i * 18
    lg.setColor(0.5, 0.6, 0.7, 0.7)
    lg.print(line[1], sPanelX + 8, y)
    lg.setColor(line[3][1], line[3][2], line[3][3], 1)
    lg.print(line[2], sPanelX + 80, y)
  end

  -- Credits
  lg.setColor(1, 0.85, 0.2, 1)
  lg.print("$" .. self.inventory.credits, sPanelX + 5, sPanelY + sPanelH - 18)

  -- Synergies
  if #self.synergies > 0 then
    local sy = sPanelY + sPanelH + 10
    lg.setColor(1, 0.8, 0.2, 0.9)
    lg.print("SYNERGIES ACTIVE:", sPanelX, sy)
    for i, syn in ipairs(self.synergies) do
      sy = sy + 16
      lg.setColor(syn.color[1], syn.color[2], syn.color[3], 0.9)
      lg.print("- " .. syn.name, sPanelX + 5, sy)
    end
  end
end

return Hangar
