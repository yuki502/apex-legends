-- Loading screen system
-- Shows progress while assets load, then transitions to main menu

local lg = love.graphics
local lw = lg.getWidth
local lh = lg.getHeight

local Loading = {}
Loading.__index = Loading

function Loading:new()
  local self = setmetatable({}, Loading)
  self.progress = 0
  self.targetProgress = 0
  self.isLoading = false
  self.isComplete = false
  self.loadTasks = {}
  self.currentTask = 1
  self.font = lg.newFont(18)
  self.bigFont = lg.newFont(36)
  self.tipFont = lg.newFont(14)
  self.tips = {
    "Tip: Press SHIFT to dodge enemy fire",
    "Tip: Collect coins to buy upgrades in the shop",
    "Tip: Every 10 waves, a boss appears",
    "Tip: Components can have powerful synergies",
    "Tip: Press P to pause the game",
    "Tip: Drag components in the hangar to customize your ship",
    "Tip: Your currency and upgrades persist between runs",
  }
  self.currentTip = 1
  self.tipTimer = 0
  return self
end

function Loading:start(tasks)
  self.loadTasks = tasks or {}
  self.currentTask = 1
  self.progress = 0
  self.targetProgress = 0
  self.isLoading = true
  self.isComplete = false
end

function Loading:update(dt)
  if not self.isLoading then return end

  -- Smooth progress animation
  if self.progress < self.targetProgress then
    self.progress = math.min(self.targetProgress, self.progress + dt * 1.5)
  end

  -- Execute loading tasks
  if self.currentTask <= #self.loadTasks then
    local task = self.loadTasks[self.currentTask]
    if task.fn then
      task.fn()
    end
    self.currentTask = self.currentTask + 1
    self.targetProgress = self.currentTask / #self.loadTasks
  else
    self.targetProgress = 1
    if self.progress >= 0.99 then
      self.isLoading = false
      self.isComplete = true
    end
  end

  -- Rotate tips
  self.tipTimer = self.tipTimer + dt
  if self.tipTimer > 4 then
    self.tipTimer = 0
    self.currentTip = (self.currentTip % #self.tips) + 1
  end
end

function Loading:draw()
  if not self.isLoading and not self.isComplete then return end

  local w, h = lw(), lh()

  -- Dark background
  lg.setColor(0.05, 0.05, 0.1, 1)
  lg.rectangle("fill", 0, 0, w, h)

  -- Subtle animated background pattern
  local t = love.timer.getTime()
  for i = 1, 30 do
    local x = (i * 127 + t * 20) % (w + 100) - 50
    local y = (i * 73 + t * 10) % (h + 100) - 50
    lg.setColor(0.2, 0.4, 0.6, 0.1 + 0.1 * math.sin(t + i))
    lg.circle("fill", x, y, 1 + math.sin(t * 2 + i) * 0.5)
  end

  -- Game title
  lg.setFont(self.bigFont)
  lg.setColor(0.3, 0.8, 1, 1)
  local title = "APEX LEGENDS"
  lg.print(title, w/2 - self.bigFont:getWidth(title)/2, h/2 - 120)

  -- Subtitle
  lg.setFont(self.font)
  lg.setColor(0.7, 0.8, 0.9, 0.8)
  local subtitle = "SPACE SHOOTER"
  lg.print(subtitle, w/2 - self.font:getWidth(subtitle)/2, h/2 - 70)

  -- Progress bar
  local barW = w * 0.6
  local barH = 8
  local barX = (w - barW) / 2
  local barY = h/2 + 20

  -- Background
  lg.setColor(0.1, 0.15, 0.25, 1)
  lg.rectangle("fill", barX, barY, barW, barH, 4, 4)

  -- Progress fill
  local fillW = barW * self.progress
  lg.setColor(0.3, 0.7, 1, 1)
  lg.rectangle("fill", barX, barY, fillW, barH, 4, 4)

  -- Progress text
  lg.setColor(1, 1, 1, 0.9)
  lg.setFont(self.font)
  local pct = math.floor(self.progress * 100)
  local progText = pct .. "%"
  lg.print(progText, w/2 - self.font:getWidth(progText)/2, barY + barH + 8)

  -- Current task name
  if self.currentTask <= #self.loadTasks then
    local task = self.loadTasks[self.currentTask]
    if task and task.name then
      lg.setFont(self.tipFont)
      lg.setColor(0.6, 0.7, 0.8, 0.7)
      lg.print(task.name, w/2 - self.tipFont:getWidth(task.name)/2, barY + barH + 32)
    end
  end

  -- Tip at bottom
  lg.setFont(self.tipFont)
  lg.setColor(0.5, 0.6, 0.7, 0.6)
  local tip = self.tips[self.currentTip]
  lg.print(tip, w/2 - self.tipFont:getWidth(tip)/2, h - 60)

  -- Loading complete flash
  if self.isComplete then
    local alpha = (math.sin(love.timer.getTime() * 8) + 1) * 0.5 * 0.3
    lg.setColor(0.3, 1, 0.5, alpha)
    lg.setFont(self.font)
    local readyText = "PRESS ANY KEY TO START"
    lg.print(readyText, w/2 - self.font:getWidth(readyText)/2, h - 100)
  end
end

function Loading:isDone()
  return self.isComplete
end

return Loading