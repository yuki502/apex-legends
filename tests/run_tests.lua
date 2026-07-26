#!/usr/bin/env lua
local script_dir = arg and arg[0] and arg[0]:match("^(.*/)") or "./"
local project_dir = script_dir .. ".."

package.path = project_dir .. "/?.lua;" .. project_dir .. "/?/init.lua;" .. package.path

local runner = require("tests.test_runner")

local testFiles = {
  "tests/unit/test_constants.lua",
  "tests/unit/test_synergies.lua",
}

local success = true

for _, file in ipairs(testFiles) do
  local ok = runner.runFile(file)
  if not ok then
    success = false
  end
end

if success then
  print("All tests passed!")
  os.exit(0)
else
  print("Some tests failed!")
  os.exit(1)
end
