-- test.lua
-- Entry point for running unit tests in CI.
-- Usage: love test.lua

local runner = require("tests.test_runner")

local testFiles = {
  "tests/unit/test_constants.lua",
  "tests/unit/test_synergies.lua",
  "tests/unit/test_benchmarks.lua",
}

local success = true
for _, file in ipairs(testFiles) do
  local ok = runner.runFile(file)
  if not ok then success = false end
end

if success then
  love.event.quit(0)
else
  love.event.quit(1)
end
