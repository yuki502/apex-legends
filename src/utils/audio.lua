-- audio.lua
-- Gestión de audio: efectos de sonido y música.
-- Carga archivos .ogg/.mp3 desde assets/audio/.
-- Soporta: play sloop, play music, volumen configurable.
-- La música se reproduce en loop, efectos se reproducen una vez.

local Audio = {}

local sounds = {}         -- Efectos de sonido cargados
local musicTracks = {}    -- Pistas de música cargadas
local currentMusic = nil  -- Pista de música actual

function Audio.load()
  local sfxFiles = {
    shoot = "assets/audio/shoot.ogg",
    explosion = "assets/audio/explosion.ogg",
    hit = "assets/audio/hit.ogg",
    gameover = "assets/audio/gameover.ogg",
  }
  for name, path in pairs(sfxFiles) do
    local ok, source = pcall(love.audio.newSource, path, "static")
    if ok and source then
      sounds[name] = source
    end
  end

  local ok, src = pcall(love.audio.newSource, "assets/audio/menu.mp3", "stream")
  if ok and src then
    musicTracks.menu = src
  end

  musicTracks.gameplay = {}
  local gameTracks = {"assets/audio/the_long_road_home.mp3", "assets/audio/waiting_for_the_new_day.mp3"}
  for _, path in ipairs(gameTracks) do
    local ok, src = pcall(love.audio.newSource, path, "stream")
    if ok and src then
      table.insert(musicTracks.gameplay, src)
    end
  end
end

function Audio.play(name)
  local s = sounds[name]
  if s then
    s:stop()
    s:play()
  end
end

function Audio.playMenuMusic()
  Audio.stopMusic()
  local s = musicTracks.menu
  if s then
    s:setLooping(true)
    s:play()
    currentMusic = s
  end
end

function Audio.playGameMusic()
  Audio.stopMusic()
  local tracks = musicTracks.gameplay
  if #tracks == 0 then return end
  local s = tracks[love.math.random(1, #tracks)]
  s:setLooping(true)
  s:play()
  currentMusic = s
end

function Audio.stopMusic()
  if currentMusic then
    currentMusic:stop()
    currentMusic = nil
  end
end

return Audio
