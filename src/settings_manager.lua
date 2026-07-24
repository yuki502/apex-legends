local SettingsManager = {}

local _defaults = {
  musicVol = 0.7,
  sfxVol = 0.8,
  handedness = "right",
}

local _data = {}

function SettingsManager.init()
  SettingsManager.load()
end

function SettingsManager.load()
  for k, v in pairs(_defaults) do
    _data[k] = v
  end
  local ok, content = pcall(love.filesystem.read, "settings.dat")
  if ok and content then
    for line in content:gmatch("[^\n]+") do
      local k, v = line:match("^([^=]+)=(.+)$")
      if k and v and _defaults[k] ~= nil then
        local num = tonumber(v)
        if num then
          _data[k] = num
        elseif v == "left" or v == "right" then
          _data[k] = v
        end
      end
    end
  end
end

function SettingsManager.save()
  local lines = {}
  for k, v in pairs(_data) do
    lines[#lines + 1] = k .. "=" .. tostring(v)
  end
  pcall(love.filesystem.write, "settings.dat", table.concat(lines, "\n"))
end

function SettingsManager.get(key)
  return _data[key]
end

function SettingsManager.set(key, value)
  _data[key] = value
  SettingsManager.save()
end

function SettingsManager.getMusicVol()
  return _data.musicVol
end

function SettingsManager.getSfxVol()
  return _data.sfxVol
end

function SettingsManager.setMusicVol(v)
  _data.musicVol = math.max(0, math.min(1, v))
  SettingsManager.save()
end

function SettingsManager.setSfxVol(v)
  _data.sfxVol = math.max(0, math.min(1, v))
  SettingsManager.save()
end

function SettingsManager.isLeftHanded()
  return _data.handedness == "left"
end

function SettingsManager.setHandedness(h)
  _data.handedness = h
  SettingsManager.save()
end

function SettingsManager.toggleHandedness()
  _data.handedness = _data.handedness == "right" and "left" or "right"
  SettingsManager.save()
end

return SettingsManager
