local runner = require("tests.test_runner")
local C = require("src.data.constants")

runner.describe("Constants Module", function()

  runner.it("should define display dimensions", function()
    runner.assertEqual(C.DESIGN_W, 700)
    runner.assertEqual(C.DESIGN_H, 400)
  end)

  runner.it("should define player defaults", function()
    runner.assert(C.PLAYER_SPEED > 0)
    runner.assert(C.PLAYER_MAX_HP > 0)
    runner.assert(C.PLAYER_DODGE_DURATION > 0)
  end)

  runner.it("should define combat thresholds", function()
    runner.assert(C.COMBO_THRESHOLD_MED < C.COMBO_THRESHOLD_HIGH)
    runner.assert(C.BOSS_WAVE_INTERVAL > 0)
    runner.assert(C.SHOP_WAVE_INTERVAL > 0)
  end)

  runner.it("should define economy values", function()
    runner.assert(C.COIN_KILL_BASE > 0)
    runner.assert(C.UPGRADE_BASE_COST > 0)
    runner.assert(C.UPGRADE_MAX_LEVEL > 0)
  end)

  runner.it("should define save file names", function()
    runner.assert(#C.SAVE_CURRENCY > 0)
    runner.assert(#C.SAVE_SETTINGS > 0)
  end)

end)

return runner
