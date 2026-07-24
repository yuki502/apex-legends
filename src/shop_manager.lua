local lg = love.graphics
local lw = lg.getWidth
local lh = lg.getHeight
local floor = math.floor
local sin = math.sin

local CurrencyManager = require("src.currency_manager")
local UpgradeManager = require("src.upgrade_manager")
local ConsumableManager = require("src.consumable_manager")
local ComponentDefs = require("src.component_defs")

local ShopManager = {}

local _tab = "upgrades"
local _scrollY = 0
local _buttons = {}
local _animT = 0
local _open = false
local _toast = nil
local _toastTimer = 0
local _hoverIdx = 0

local PADDING = 8
local BTN_H = 38
local TAB_H = 30

local _closeBtn = {x = 0, y = 0, w = 0, h = 0}

function ShopManager.open()
  _open = true
  _tab = "upgrades"
  _scrollY = 0
  _animT = 0
  _toast = nil
  _toastTimer = 0
end

function ShopManager.isOpen()
  return _open
end

function ShopManager.close()
  _open = false
end

function ShopManager.showToast(text, color)
  _toast = {text = text, color = color or {1, 1, 1}, timer = 1.5}
end

function ShopManager.update(dt)
  if not _open then return end
  _animT = _animT + dt
  if _toast then
    _toast.timer = _toast.timer - dt
    if _toast.timer <= 0 then _toast = nil end
  end
end

function ShopManager.draw(g)
  if not _open then return end
  local w, h = lw(), lh()

  lg.setColor(0, 0, 0, 0.85)
  lg.rectangle("fill", 0, 0, w, h)

  local panelW = math.min(w - 20, 580)
  local panelH = h - 30
  local px = (w - panelW) / 2
  local py = 15

  lg.setColor(0.08, 0.1, 0.16, 0.95)
  lg.rectangle("fill", px, py, panelW, panelH, 8, 8)
  lg.setColor(0.2, 0.5, 0.8, 0.6)
  lg.setLineWidth(1)
  lg.rectangle("line", px, py, panelW, panelH, 8, 8)

  lg.setFont(g.smallFont)
  lg.setColor(1, 0.85, 0.2, 1)
  local coinText = "COINS: " .. CurrencyManager.get()
  lg.print(coinText, px + PADDING, py + 6)

  lg.setFont(g.font)
  lg.setColor(0.9, 0.9, 0.9, 1)
  local title = "SUPPLY SHOP"
  lg.print(title, px + panelW / 2 - g.font:getWidth(title) / 2, py + 6)

  local tabY = py + 32
  local tabs = {"upgrades", "items", "components"}
  local tabLabels = {"UPGRADES", "ITEMS", "COMPONENTS"}
  local tabW = (panelW - PADDING * 2) / #tabs

  for i = 1, #tabs do
    local tx = px + PADDING + (i - 1) * tabW
    local active = _tab == tabs[i]
    if active then
      lg.setColor(0.2, 0.5, 0.8, 0.6)
      lg.rectangle("fill", tx, tabY, tabW - 4, TAB_H, 4, 4)
    end
    lg.setFont(g.smallFont)
    lg.setColor(1, 1, 1, active and 1 or 0.5)
    lg.print(tabLabels[i], tx + tabW / 2 - g.smallFont:getWidth(tabLabels[i]) / 2, tabY + 8)
  end

  local contentY = tabY + TAB_H + PADDING
  local contentH = panelH - (contentY - py) - BTN_H - PADDING * 2

  lg.setColor(0, 0, 0, 0.3)
  lg.rectangle("fill", px + PADDING, contentY, panelW - PADDING * 2, contentH, 4, 4)

  lg.setScissor(px + PADDING, contentY, panelW - PADDING * 2, contentH)

  _buttons = {}
  local itemY = contentY - _scrollY

  if _tab == "upgrades" then
    local upgrades = UpgradeManager.getAll()
    for i, up in ipairs(upgrades) do
      if itemY + BTN_H > contentY - BTN_H and itemY < contentY + contentH then
        local bx = px + PADDING + 4
        local by = itemY
        local bw = panelW - PADDING * 2 - 8

        local canAfford = CurrencyManager.canAfford(up.cost)
        local canBuy = up.canBuy and canAfford

        if canBuy then
          lg.setColor(up.color[1], up.color[2], up.color[3], 0.2)
          lg.rectangle("fill", bx, by, bw, BTN_H - 2, 4, 4)
        end

        lg.setColor(up.color[1], up.color[2], up.color[3], canBuy and 0.9 or 0.4)
        lg.setFont(g.smallFont)
        lg.print(up.icon, bx + 6, by + 10)

        lg.setColor(1, 1, 1, canBuy and 0.9 or 0.4)
        lg.setFont(g.smallFont)
        lg.print(up.name, bx + 32, by + 4)
        lg.setColor(0.7, 0.7, 0.7, canBuy and 0.7 or 0.3)
        lg.print(up.desc, bx + 32, by + 18)

        if not up.consumable then
          local lvlText = "Lv." .. up.level .. "/" .. up.maxLevel
          lg.setColor(0.6, 0.6, 0.6, canBuy and 0.8 or 0.3)
          lg.print(lvlText, bx + bw - 70, by + 4)
        end

        local costColor = canBuy and {0.3, 1, 0.5} or {1, 0.3, 0.3}
        lg.setColor(costColor[1], costColor[2], costColor[3], canBuy and 0.9 or 0.4)
        lg.print(up.cost .. "c", bx + bw - 40, by + 18)

        if canBuy then
          _buttons[#_buttons + 1] = {x = bx, y = by, w = bw, h = BTN_H - 2, action = "upgrade", key = up.key}
        end
      end
      itemY = itemY + BTN_H
    end
  elseif _tab == "items" then
    local items = ConsumableManager.getAll()
    for i, item in ipairs(items) do
      if itemY + BTN_H > contentY - BTN_H and itemY < contentY + contentH then
        local bx = px + PADDING + 4
        local by = itemY
        local bw = panelW - PADDING * 2 - 8

        local canBuy = ConsumableManager.canBuy(item.key)

        if canBuy then
          lg.setColor(item.color[1], item.color[2], item.color[3], 0.2)
          lg.rectangle("fill", bx, by, bw, BTN_H - 2, 4, 4)
        end

        lg.setColor(item.color[1], item.color[2], item.color[3], canBuy and 0.9 or 0.4)
        lg.setFont(g.smallFont)
        lg.print(item.icon, bx + 6, by + 10)

        lg.setColor(1, 1, 1, canBuy and 0.9 or 0.4)
        lg.setFont(g.smallFont)
        lg.print(item.name, bx + 32, by + 4)
        lg.setColor(0.7, 0.7, 0.7, canBuy and 0.7 or 0.3)
        lg.print(item.desc, bx + 32, by + 18)

        local stockText = item.stock .. "/" .. item.maxStock
        lg.setColor(0.6, 0.6, 0.6, canBuy and 0.8 or 0.3)
        lg.print(stockText, bx + bw - 55, by + 4)

        local costColor = canBuy and {0.3, 1, 0.5} or {1, 0.3, 0.3}
        lg.setColor(costColor[1], costColor[2], costColor[3], canBuy and 0.9 or 0.4)
        lg.print(item.cost .. "c", bx + bw - 40, by + 18)

        if canBuy then
          _buttons[#_buttons + 1] = {x = bx, y = by, w = bw, h = BTN_H - 2, action = "item", key = item.key}
        end
      end
      itemY = itemY + BTN_H
    end
  elseif _tab == "components" then
    local drops = g.componentDropPool or {}
    for i, drop in ipairs(drops) do
      if itemY + BTN_H > contentY - BTN_H and itemY < contentY + contentH then
        local bx = px + PADDING + 4
        local by = itemY
        local bw = panelW - PADDING * 2 - 8
        local comp = drop.comp
        local canBuy = not drop.bought and CurrencyManager.canAfford(drop.price)

        if canBuy then
          lg.setColor(comp.rarityColor[1], comp.rarityColor[2], comp.rarityColor[3], 0.15)
          lg.rectangle("fill", bx, by, bw, BTN_H - 2, 4, 4)
        elseif drop.bought then
          lg.setColor(0.2, 0.6, 0.3, 0.15)
          lg.rectangle("fill", bx, by, bw, BTN_H - 2, 4, 4)
        end

        -- rarity dot
        lg.setColor(comp.rarityColor[1], comp.rarityColor[2], comp.rarityColor[3], canBuy and 0.9 or 0.4)
        lg.circle("fill", bx + 10, by + BTN_H / 2, 4)

        lg.setColor(1, 1, 1, canBuy and 0.9 or (drop.bought and 0.5 or 0.4))
        lg.setFont(g.smallFont)
        lg.print(comp.name, bx + 22, by + 4)

        local slotCat = ComponentDefs.CATEGORIES[comp.slot]
        lg.setColor(0.6, 0.6, 0.6, canBuy and 0.6 or 0.3)
        lg.print((slotCat and slotCat.label or comp.slot) .. " | " .. comp.rarityLabel, bx + 22, by + 18)

        if drop.bought then
          lg.setColor(0.3, 1, 0.5, 0.9)
          lg.print("SOLD", bx + bw - 50, by + 10)
        else
          lg.setColor(1, 0.85, 0.2, canBuy and 0.9 or 0.4)
          lg.print(drop.price .. "c", bx + bw - 40, by + 10)

          if canBuy then
            _buttons[#_buttons + 1] = {x = bx, y = by, w = bw, h = BTN_H - 2, action = "component", key = i, data = drop}
          end
        end
      end
      itemY = itemY + BTN_H
    end

    if #drops == 0 then
      lg.setColor(0.5, 0.5, 0.5, 0.7)
      lg.setFont(g.smallFont)
      lg.print("No components available this visit", px + panelW / 2 - 100, contentY + 20)
    end
  end

  lg.setScissor()

  local btnY = py + panelH - BTN_H - PADDING
  local btnW = (panelW - PADDING * 3) / 2

  lg.setColor(0.2, 0.7, 0.4, 0.6)
  lg.rectangle("fill", px + PADDING, btnY, btnW, BTN_H, 6, 6)
  lg.setColor(1, 1, 1, 0.9)
  lg.setFont(g.font)
  lg.print("CONTINUE", px + PADDING + btnW / 2 - g.font:getWidth("CONTINUE") / 2, btnY + 9)
  _buttons[#_buttons + 1] = {x = px + PADDING, y = btnY, w = btnW, h = BTN_H, action = "continue"}

  _closeBtn = {x = px + PADDING * 2 + btnW, y = btnY, w = btnW, h = BTN_H}
  lg.setColor(0.5, 0.2, 0.2, 0.5)
  lg.rectangle("fill", _closeBtn.x, _closeBtn.y, _closeBtn.w, _closeBtn.h, 6, 6)
  lg.setColor(1, 1, 1, 0.6)
  lg.print("HANGAR", _closeBtn.x + btnW / 2 - g.font:getWidth("HANGAR") / 2, btnY + 9)
  _buttons[#_buttons + 1] = {x = _closeBtn.x, y = _closeBtn.y, w = _closeBtn.w, h = _closeBtn.h, action = "hangar"}

  if _toast then
    local alpha = math.min(_toast.timer, 0.5) * 2
    lg.setColor(_toast.color[1], _toast.color[2], _toast.color[3], alpha * 0.3)
    lg.rectangle("fill", w / 2 - 80, h - 50, 160, 28, 6, 6)
    lg.setColor(_toast.color[1], _toast.color[2], _toast.color[3], alpha)
    lg.setFont(g.smallFont)
    lg.print(_toast.text, w / 2 - g.smallFont:getWidth(_toast.text) / 2, h - 44)
  end
end

function ShopManager.handleInput(g, tx, ty)
  if not _open then return false end
  for _, btn in ipairs(_buttons) do
    if tx >= btn.x and tx <= btn.x + btn.w and ty >= btn.y and ty <= btn.y + btn.h then
      if btn.action == "continue" then
        ShopManager.close()
        g:continueFromShop()
        return true
      elseif btn.action == "hangar" then
        ShopManager.close()
        g:continueFromShop()
        return true
      elseif btn.action == "upgrade" then
        local ok, cost = UpgradeManager.purchase(btn.key)
        if ok then
          ShopManager.showToast("Purchased!", {0.3, 1, 0.5})
          if btn.key == "heal" then
            g.player.lives = math.min(g.player.lives + 1, g.player.maxLives)
          elseif btn.key == "shield" then
            g.player.maxShield = g.player.maxShield + 1
            g.player.shield = g.player.shield + 1
          end
        end
        return false
      elseif btn.action == "item" then
        local ok = ConsumableManager.buy(btn.key)
        if ok then
          ShopManager.showToast("Acquired!", {0.3, 0.8, 1})
        end
        return false
      elseif btn.action == "component" then
        local ok = g:purchaseComponent(btn.key)
        if ok then
          ShopManager.showToast("Component acquired!", {0.3, 1, 0.5})
        else
          ShopManager.showToast("Not enough coins!", {1, 0.3, 0.3})
        end
        return false
      end
    end
  end
  return false
end

function ShopManager.touchpressed(g, id, tx, ty)
  return ShopManager.handleInput(g, tx, ty)
end

return ShopManager
