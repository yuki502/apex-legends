local ceil = math.ceil
local lg = love.graphics
local lw = lg.getWidth
local lh = lg.getHeight
local sin = math.sin

local CurrencyManager = require("src.currency_manager")

local POWERUP_COLORS = {
  double_shot = {1, 0.8, 0.2},
  speed = {0.2, 1, 0.4},
  magnet = {0.8, 0.3, 1},
}

local HUD = {}

function HUD.draw(g)
  local w = lw()
  local h = lh()
  local player = g.player

  if g.state == "hangar" then
    lg.setColor(1, 1, 1, 0.5)
    lg.setFont(g.smallFont)
    lg.print("WAVE " .. (g.wave + 1) .. " INCOMING - BUILD YOUR SHIP", w / 2 - 120, h - 20)
    return
  end

  if g.state == "shop" then return end

  lg.setFont(g.font)
  lg.setColor(0, 0, 0, 0.35)
  lg.rectangle("fill", 0, 0, w, 60)
  lg.setColor(1, 1, 1, 0.08)
  lg.setLineWidth(1)
  lg.line(0, 60, w, 60)

  lg.setColor(1, 1, 1, 0.85)
  lg.print("SCORE", 12, 6)
  lg.setColor(0.3, 1, 0.6, 1)
  lg.print(g.score, 12, 26)

  if g.combo > 1 then
    lg.setColor(1, 0.9, 0.3, 0.7)
    lg.print("x" .. g.combo, 12, 42)
  end

  local coins = CurrencyManager.get()
  lg.setColor(1, 0.85, 0.2, 0.9)
  lg.setFont(g.smallFont)
  local coinText = "COINS: " .. coins
  lg.print(coinText, 80, 6)

  lg.setColor(1, 1, 1, 0.5)
  lg.setFont(g.smallFont)
  lg.print("WAVE " .. g.wave, w / 2 - 25, 6)

  if g.boss then
    lg.setColor(1, 0.2, 0.2, 0.8)
    lg.print("BOSS", w / 2 - g.smallFont:getWidth("BOSS") / 2, 22)
  end

  if g.waveCountdown and g.waveCountdown > 0 then
    local alpha = math.min(g.waveCountdown, 1)
    lg.setFont(g.bigFont)
    lg.setColor(1, 1, 1, alpha * 0.8)
    local countText = tostring(ceil(g.waveCountdown))
    lg.print(countText, w / 2 - g.bigFont:getWidth(countText) / 2, h / 2 - 40)
    lg.setFont(g.smallFont)
    lg.setColor(1, 1, 1, alpha * 0.5)
    lg.print("NEXT WAVE", w / 2 - g.smallFont:getWidth("NEXT WAVE") / 2, h / 2 + 10)
  end

  lg.setColor(1, 1, 1, 0.85)
  lg.setFont(g.font)
  local lx = w - 140
  lg.print("LIVES", lx, 6)
  for i = 1, player.lives do
    local hx = lx + (i - 1) * 20
    lg.setColor(1, 0.2, 0.2, 0.8)
    lg.polygon("fill", hx, 38, hx + 4, 26, hx + 8, 32, hx + 12, 26, hx + 16, 38, hx + 8, 44)
  end

  if player.shield > 0 then
    lg.setColor(0.2, 0.6, 1, 0.8)
    lg.setFont(g.smallFont)
    lg.print("SHIELD", lx, 44)
    for i = 1, player.shield do
      lg.setColor(0.2, 0.6, 1, 0.7)
      lg.circle("fill", lx + (i - 1) * 14 + 40, 48, 4)
    end
  end

  local py = 6
  for name, data in pairs(player.powerups) do
    local c = POWERUP_COLORS[name]
    if c then
      lg.setColor(c[1], c[2], c[3], 0.8)
    else
      lg.setColor(1, 1, 1, 0.8)
    end
    lg.setFont(g.smallFont)
    lg.print(name:sub(1, 4) .. " " .. ceil(data.timer) .. "s", w / 2 + 60, py)
    py = py + 14
  end

  if player.hasDamageBoost then
    lg.setColor(1, 0.3, 0.2, 0.8)
    lg.setFont(g.smallFont)
    lg.print("AMP " .. ceil(player.damageTimer) .. "s", w / 2 + 60, py)
    py = py + 14
  end
  if player.hasSpeedItem then
    lg.setColor(0.2, 0.8, 1, 0.8)
    lg.setFont(g.smallFont)
    lg.print("TURBO " .. ceil(player.speedTimer) .. "s", w / 2 + 60, py)
    py = py + 14
  end

  if g.boss then
    HUD.drawBossBar(g)
  end
end

function HUD.drawBossBar(g)
  local w = lw()
  local boss = g.boss
  local hpRatio = boss.hp / boss.maxHp
  local barW = 250
  local barH = 8
  local barX = w / 2 - barW / 2
  local barY = 40

  lg.setColor(0, 0, 0, 0.5)
  lg.rectangle("fill", barX - 1, barY - 1, barW + 2, barH + 2, 3, 3)
  lg.setColor(0.2, 0.2, 0.2, 0.8)
  lg.rectangle("fill", barX, barY, barW, barH, 2, 2)

  local r, g2, b
  if hpRatio > 0.5 then
    r, g2, b = 0.2, 0.9, 0.3
  elseif hpRatio > 0.25 then
    r, g2, b = 1, 0.7, 0.2
  else
    r, g2, b = 1, 0.2, 0.2
  end
  lg.setColor(r, g2, b, 0.9)
  lg.rectangle("fill", barX, barY, barW * hpRatio, barH, 2, 2)

  lg.setColor(1, 1, 1, 0.6)
  lg.setFont(g.tinyFont)
  local bossName = boss.name or "BOSS"
  lg.print(bossName, barX, barY - 10)
end

function HUD.drawGameOver(g)
  local w = lw()
  local h = lh()

  lg.setColor(0, 0, 0, 0.6)
  lg.rectangle("fill", 0, 0, w, h)

  lg.setFont(g.bigFont)
  lg.setColor(1, 0.2, 0.2, 1)
  lg.print("GAME OVER", w / 2 - g.bigFont:getWidth("GAME OVER") / 2, h / 2 - 80)

  lg.setFont(g.titleFont)
  local scoreText = "SCORE: " .. g.score
  lg.setColor(1, 1, 1, 0.7)
  lg.print(scoreText, w / 2 - g.titleFont:getWidth(scoreText) / 2, h / 2 - 40)

  local coinText = "COINS EARNED: " .. CurrencyManager.getTotal()
  lg.setColor(1, 0.85, 0.2, 0.7)
  lg.print(coinText, w / 2 - g.titleFont:getWidth(coinText) / 2, h / 2 - 10)

  if g.score >= g.highScore and g.score > 0 then
    lg.setColor(1, 0.8, 0.2, 0.9)
    lg.print("NEW RECORD!", w / 2 - g.titleFont:getWidth("NEW RECORD!") / 2, h / 2 + 20)
  else
    lg.setFont(g.smallFont)
    lg.setColor(1, 0.8, 0.2, 0.6)
    local hsText = "RECORD: " .. g.highScore
    lg.print(hsText, w / 2 - g.smallFont:getWidth(hsText) / 2, h / 2 + 18)
  end

  lg.setFont(g.smallFont)
  lg.setColor(1, 1, 1, 0.5)
  local stats = "Wave: " .. g.wave .. " | Kills: " .. g.totalKills .. " | Max Combo: x" .. g.maxCombo
  lg.print(stats, w / 2 - g.smallFont:getWidth(stats) / 2, h / 2 + 44)

  lg.setFont(g.font)
  lg.setColor(1, 1, 1, 0.4)
  lg.print("TAP TO RESTART", w / 2 - g.font:getWidth("TAP TO RESTART") / 2, h / 2 + 70)
end

function HUD.drawPause(g)
  local w, h = lw(), lh()

  lg.setColor(0, 0, 0, 0.5)
  lg.rectangle("fill", 0, 0, w, h)

  lg.setFont(g.bigFont)
  lg.setColor(0.3, 0.8, 1, 1)
  lg.print("PAUSED", w / 2 - g.bigFont:getWidth("PAUSED") / 2, h / 2 - 50)

  lg.setFont(g.font)
  lg.setColor(1, 1, 1, 0.5)
  lg.print("TAP TO RESUME", w / 2 - g.font:getWidth("TAP TO RESUME") / 2, h / 2 + 10)

  lg.setFont(g.smallFont)
  lg.setColor(1, 1, 1, 0.4)
  lg.print("SCORE: " .. g.score, w / 2 - g.smallFont:getWidth("SCORE: " .. g.score) / 2, h / 2 + 40)
end

return HUD
