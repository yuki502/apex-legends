local runner = require("tests.test_runner")

runner.describe("Performance Benchmarks", function()

  runner.it("should measure table creation vs reuse", function()
    local iterations = 100000

    local start = love.timer.getTime()
    local sum = 0
    for i = 1, iterations do
      local t = {}
      t.x = i
      t.y = i * 2
      sum = sum + t.x + t.y
    end
    local createTime = love.timer.getTime() - start

    start = love.timer.getTime()
    sum = 0
    local t = {}
    for i = 1, iterations do
      t.x = i
      t.y = i * 2
      sum = sum + t.x + t.y
    end
    local reuseTime = love.timer.getTime() - start

    print(string.format("  Table creation: %.4fs", createTime))
    print(string.format("  Table reuse:    %.4fs", reuseTime))
    print(string.format("  Speedup: %.1fx", createTime / reuseTime))
  end)

  runner.it("should measure string concatenation methods", function()
    local iterations = 50000
    local parts = {"hello", "world", "this", "is", "a", "test"}

    local start = love.timer.getTime()
    local s = ""
    for i = 1, iterations do
      s = parts[1] .. parts[2] .. parts[3] .. parts[4] .. parts[5]
    end
    local concatTime = love.timer.getTime() - start

    start = love.timer.getTime()
    for i = 1, iterations do
      s = table.concat(parts, " ", 1, 5)
    end
    local tableConcatTime = love.timer.getTime() - start

    print(string.format("  String concat:  %.4fs", concatTime))
    print(string.format("  table.concat:   %.4fs", tableConcatTime))
  end)

end)

return runner
