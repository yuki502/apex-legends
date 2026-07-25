local runner = require("tests.test_runner")
local SynergySystem = require("src.systems.synergy_system")
local ComponentDefs = require("src.data.component_defs")

local function makeComp(slot, id)
  return {slot = slot, id = id or ("test_" .. slot)}
end

runner.describe("Synergy System", function()

  runner.it("should detect no synergies with empty list", function()
    local result = SynergySystem.check({})
    runner.assertEqual(#result, 0)
  end)

  runner.it("should detect Fortress with shield + armor + HP mod", function()
    local comps = {
      makeComp("shield"),
      makeComp("armor"),
      makeComp("module", "mod_hp"),
    }
    local result = SynergySystem.check(comps)
    local found = false
    for _, id in ipairs(result) do
      if id == "full_defense" then found = true end
    end
    runner.assert(found, "Expected Fortress synergy (full_defense)")
  end)

  runner.it("should detect Speed Demon with thruster + engine + speed mod", function()
    local comps = {
      makeComp("thruster"),
      makeComp("engine"),
      makeComp("module", "mod_speed"),
    }
    local result = SynergySystem.check(comps)
    local found = false
    for _, id in ipairs(result) do
      if id == "speed_demon" then found = true end
    end
    runner.assert(found, "Expected Speed Demon synergy (speed_demon)")
  end)

  runner.it("should detect Arsenal with 3+ weapons", function()
    local comps = {
      makeComp("weapon", "wpn1"),
      makeComp("weapon", "wpn2"),
      makeComp("weapon", "wpn3"),
    }
    local result = SynergySystem.check(comps)
    local found = false
    for _, id in ipairs(result) do
      if id == "full_weapon" then found = true end
    end
    runner.assert(found, "Expected Arsenal synergy (full_weapon)")
  end)

  runner.it("should return all defined synergies", function()
    local all = SynergySystem.getAll()
    runner.assert(#all > 0)
  end)

end)

return runner
