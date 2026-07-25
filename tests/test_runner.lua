local runner = {}
local tests = {}
local passed = 0
local failed = 0

function runner.describe(name, fn)
  table.insert(tests, {type = "describe", name = name, fn = fn})
end

function runner.it(name, fn)
  table.insert(tests, {type = "it", name = name, fn = fn})
end

function runner.assert(condition, message)
  if not condition then
    error(message or "Assertion failed", 2)
  end
end

function runner.assertEqual(a, b, message)
  if a ~= b then
    error(message or string.format("Expected %s, got %s", tostring(b), tostring(a)), 2)
  end
end

function runner.assertApprox(a, b, epsilon)
  epsilon = epsilon or 0.001
  if math.abs(a - b) > epsilon then
    error(string.format("Expected ~%s, got %s", tostring(b), tostring(a)), 2)
  end
end

function runner.run()
  print("========================================")
  print("  Test Runner")
  print("========================================")
  print()

  local currentDescribe = ""

  for _, test in ipairs(tests) do
    if test.type == "describe" then
      currentDescribe = test.name
      print("  " .. currentDescribe)
    elseif test.type == "it" then
      local ok, err = pcall(test.fn)
      if ok then
        print("    ✓ " .. test.name)
        passed = passed + 1
      else
        print("    ✗ " .. test.name)
        print("      " .. tostring(err):gsub("\n", "\n      "))
        failed = failed + 1
      end
    end
  end

  print()
  print("========================================")
  print(string.format("  %d passed, %d failed", passed, failed))
  print("========================================")

  return failed == 0
end

function runner.runFile(path)
  local ok, err = pcall(dofile, path)
  if not ok then
    print("Failed to load test file: " .. path)
    print("  " .. tostring(err))
    return false
  end
  return runner.run()
end

return runner
