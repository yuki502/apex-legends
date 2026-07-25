local ComponentDefs = require("src.data.component_defs")
local sandbox = require("tests.sandbox.sandbox")

sandbox.register("Components: list by slot", function()
  local weapons = ComponentDefs.getBySlot("weapon")
  assert(#weapons > 0, "Should have at least one weapon")
  print("  Found " .. #weapons .. " weapons")
  for _, comp in ipairs(weapons) do
    print("    " .. comp.id .. ": " .. comp.name .. " (rarity " .. comp.rarity .. ")")
  end
end)

sandbox.register("Components: random by slot", function()
  local comp = ComponentDefs.getRandomBySlot("weapon", 50)
  assert(comp ~= nil, "Should get a random weapon")
  assert(comp.slot == "weapon", "Should be a weapon")
  print("  Random weapon: " .. comp.name .. " (rarity " .. comp.rarity .. ")")
end)

sandbox.register("Components: synergy map", function()
  local synergies = ComponentDefs.getSynergyMap()
  local count = 0
  for _ in pairs(synergies) do count = count + 1 end
  print("  " .. count .. " synergy definitions loaded")
end)

sandbox.register("Components: all slots present", function()
  local expected = {"weapon", "thruster", "core", "engine", "wing", "shield", "armor", "multiplier"}
  for _, slot in ipairs(expected) do
    local comps = ComponentDefs.getBySlot(slot)
    assert(#comps > 0, "Slot '" .. slot .. "' should have at least one component")
    print("  Slot '" .. slot .. "': " .. #comps .. " components")
  end
end)

return sandbox
