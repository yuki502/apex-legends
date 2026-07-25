-- Sandbox: a lightweight environment for testing systems without starting a full game.
-- Run via: love . --sandbox

local lg = love.graphics
local font = lg.newFont(14)

local sandbox = {}
local currentTest = nil
local testNames = {}
local selected = 1
local scrollY = 0

local tests = {}

function sandbox.register(name, fn)
  tests[name] = fn
  table.insert(testNames, name)
end

function sandbox.run(name)
  if tests[name] then
    currentTest = name
    tests[name]()
  end
end

function sandbox.update(dt)
  if love.keyboard.isDown("down") and not sandbox._down then
    sandbox._down = true
    selected = math.min(selected + 1, #testNames)
  elseif not love.keyboard.isDown("down") then
    sandbox._down = false
  end

  if love.keyboard.isDown("up") and not sandbox._up then
    sandbox._up = true
    selected = math.max(selected - 1, 1)
  elseif not love.keyboard.isDown("up") then
    sandbox._up = false
  end

  if love.keyboard.isDown("return") and not sandbox._enter then
    sandbox._enter = true
    if testNames[selected] then
      sandbox.run(testNames[selected])
    end
  elseif not love.keyboard.isDown("return") then
    sandbox._enter = false
  end
end

function sandbox.draw()
  lg.setColor(0.1, 0.1, 0.15)
  lg.rectangle("fill", 0, 0, 300, love.graphics.getHeight())

  lg.setColor(1, 1, 1)
  lg.setFont(font)
  lg.print("SANDBOX (↑↓ select, ENTER run, ESC exit)", 10, 10)

  local y = 40
  for i, name in ipairs(testNames) do
    if i == selected then
      lg.setColor(1, 1, 0)
    else
      lg.setColor(0.7, 0.7, 0.7)
    end
    lg.print(name, 20, y)
    y = y + 20
  end

  if currentTest then
    lg.setColor(0.3, 1, 0.3)
    lg.print("Running: " .. currentTest, 320, 10)
  end
end

return sandbox
