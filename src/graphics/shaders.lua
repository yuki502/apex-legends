-- shaders.lua
-- Programas GLSL para shaders del juego.
-- Incluye: post-procesado de luces, fondo de estrellas, nebulosas.
-- Compatible con GLES (usa precision mediump float).
-- Los shaders se compilan una vez y se reutilizan.

local lg = love.graphics
local lgNewShader = lg.newShader

local Shaders = {}

-- ============================================================
-- SHARED VERTEX SHADER (GLES compatible)
-- ============================================================
local VERT_SRC = [[
#ifdef GL_ES
precision mediump float;
#endif
attribute vec2 VertexPosition;
attribute vec2 VertexTexCoord;
varying vec2 v_texCoord;
uniform mat4 transformMatrix;
void main() {
  v_texCoord = VertexTexCoord;
  gl_Position = transformMatrix * vec4(VertexPosition, 0.0, 1.0);
}
]]

-- ============================================================
-- SUN FRAGMENT SHADER — procedural star with glow + granulation
-- ============================================================
local SUN_FRAG = [[
#ifdef GL_ES
precision mediump float;
#endif
varying vec2 v_texCoord;
uniform float Time;
uniform vec3 StarColor;
uniform float Intensity;
uniform float StarSeed;

float hash(vec2 p) {
  return fract(sin(dot(p, vec2(127.1 + StarSeed, 311.7 + StarSeed))) * 43758.5453);
}

float vnoise(vec2 p) {
  vec2 i = floor(p);
  vec2 f = fract(p);
  f = f * f * (3.0 - 2.0 * f);
  float a = hash(i);
  float b = hash(i + vec2(1.0, 0.0));
  float c = hash(i + vec2(0.0, 1.0));
  float d = hash(i + vec2(1.0, 1.0));
  return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float fbm(vec2 p) {
  float v = 0.0;
  float a = 0.5;
  vec2 shift = vec2(100.0);
  for (int i = 0; i < 5; i++) {
    v += a * vnoise(p);
    p = p * 2.1 + shift;
    a *= 0.48;
  }
  return v;
}

void main() {
  vec2 uv = v_texCoord * 2.0 - 1.0;
  float dist = length(uv);
  if (dist > 1.4) { gl_FragColor = vec4(0.0); return; }

  float t = Time * 0.15;

  float gran = fbm(uv * 3.5 + vec2(t * 0.8, t * 0.3));
  float gran2 = fbm(uv * 7.0 - vec2(t * 0.5, t * 1.1));

  float spots = smoothstep(0.42, 0.48, gran2) * 0.25;

  float convection = sin(atan(uv.y, uv.x) * 8.0 + t * 2.0) * 0.5 + 0.5;
  convection *= gran;

  float coreBright = 1.0 - smoothstep(0.0, 0.55, dist);
  float midRing = exp(-pow(dist - 0.35, 2.0) * 20.0) * 0.4;
  float glow = exp(-dist * 2.8) * 0.6;
  float outerGlow = exp(-dist * 1.5) * 0.2;

  float brightness = coreBright * 1.2 + midRing + glow + outerGlow;
  brightness *= 0.75 + convection * 0.35;
  brightness -= spots;
  brightness = max(brightness, outerGlow * 0.5);

  float flicker = 1.0 + sin(Time * 4.7 + StarSeed * 6.28) * 0.04
                     + sin(Time * 7.3 + StarSeed * 3.14) * 0.02;

  vec3 hotCenter = StarColor * 1.4 + vec3(0.15, 0.1, 0.05);
  vec3 col = mix(StarColor, hotCenter, coreBright);
  col *= brightness * flicker * Intensity;

  float alpha = clamp(brightness * 1.2, 0.0, 1.0);
  alpha = max(alpha, outerGlow * 0.4);

  gl_FragColor = vec4(col, alpha);
}
]]

-- ============================================================
-- PLANET FRAGMENT SHADER — procedural surface with lighting
-- ============================================================
local PLANET_FRAG = [[
#ifdef GL_ES
precision mediump float;
#endif
varying vec2 v_texCoord;
uniform vec3 PlanetColor;
uniform vec3 PlanetColor2;
uniform float PlanetType;
uniform float HasAtmosphere;
uniform float PlanetSeed;
uniform float Time;

float hash(vec2 p) {
  return fract(sin(dot(p, vec2(127.1 + PlanetSeed, 311.7 + PlanetSeed))) * 43758.5453);
}

float vnoise(vec2 p) {
  vec2 i = floor(p);
  vec2 f = fract(p);
  f = f * f * (3.0 - 2.0 * f);
  float a = hash(i);
  float b = hash(i + vec2(1.0, 0.0));
  float c = hash(i + vec2(0.0, 1.0));
  float d = hash(i + vec2(1.0, 1.0));
  return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float fbm(vec2 p) {
  float v = 0.0;
  float a = 0.5;
  for (int i = 0; i < 4; i++) {
    v += a * vnoise(p);
    p = p * 2.0 + vec2(50.0);
    a *= 0.5;
  }
  return v;
}

void main() {
  vec2 uv = v_texCoord * 2.0 - 1.0;
  float dist = length(uv);
  if (dist > 1.3) { gl_FragColor = vec4(0.0); return; }

  vec3 normal = normalize(vec3(uv, sqrt(max(0.001, 1.0 - dist * dist))));
  vec3 lightDir = normalize(vec3(-0.4, -0.6, 0.8));
  float diffuse = max(dot(normal, lightDir), 0.0);
  float ambient = 0.12;
  float lighting = diffuse + ambient;

  float surface = 0.0;
  vec3 baseColor = PlanetColor;

  if (PlanetType < 0.5) {
    surface = fbm(uv * 5.0);
    float detail = fbm(uv * 12.0);
    surface = surface * 0.7 + detail * 0.3;
    baseColor = mix(PlanetColor, PlanetColor2, surface);
  } else if (PlanetType < 1.5) {
    float bands = sin(uv.y * 10.0 + vnoise(uv * 3.0) * 2.0) * 0.5 + 0.5;
    float bandDetail = vnoise(vec2(uv.x * 8.0, uv.y * 1.5 + Time * 0.02));
    bands = bands * 0.6 + bandDetail * 0.4;
    baseColor = mix(PlanetColor, PlanetColor2, bands);
    float spot = smoothstep(0.65, 0.7, vnoise(uv * 6.0 + 50.0));
    baseColor = mix(baseColor, PlanetColor * 0.7, spot * 0.4);
  } else if (PlanetType < 2.5) {
    surface = fbm(uv * 4.0 + 100.0);
    float ice = smoothstep(0.45, 0.6, surface);
    baseColor = mix(PlanetColor, PlanetColor2, ice);
    float crack = smoothstep(0.48, 0.5, vnoise(uv * 20.0 + 200.0));
    baseColor = mix(baseColor, PlanetColor2 * 1.2, crack * 0.3);
  } else {
    surface = fbm(uv * 6.0 + 300.0);
    baseColor = mix(PlanetColor, PlanetColor2, surface * 0.5);
  }

  vec3 rimColor = PlanetColor * 0.6;
  float rim = 1.0 - max(dot(normal, vec3(0.0, 0.0, 1.0)), 0.0);
  rim = pow(rim, 3.0) * 0.4;

  vec3 color = baseColor * lighting + rimColor * rim;

  float terminator = smoothstep(-0.05, 0.1, diffuse);
  color *= mix(0.3, 1.0, terminator);

  float atmo = 0.0;
  if (HasAtmosphere > 0.5) {
    float edge = smoothstep(0.75, 1.0, dist);
    atmo = edge * 0.35;
    vec3 atmoColor = mix(PlanetColor, vec3(0.4, 0.6, 1.0), 0.4);
    color += atmoColor * atmo;
  }

  float alpha = 1.0 - smoothstep(0.92, 1.0, dist);
  alpha = max(alpha, atmo * 0.5);

  gl_FragColor = vec4(color, alpha);
}
]]

-- ============================================================
-- RING FRAGMENT SHADER — planet rings
-- ============================================================
local RING_FRAG = [[
#ifdef GL_ES
precision mediump float;
#endif
varying vec2 v_texCoord;
uniform vec3 RingColor;
uniform float PlanetSeed;

float hash(vec2 p) {
  return fract(sin(dot(p, vec2(127.1 + PlanetSeed, 311.7))) * 43758.5453);
}

void main() {
  vec2 uv = v_texCoord * 2.0 - 1.0;
  float dist = length(uv);

  float innerEdge = 0.55;
  float outerEdge = 1.0;
  float ring = smoothstep(innerEdge, innerEdge + 0.03, dist) *
               (1.0 - smoothstep(outerEdge - 0.03, outerEdge, dist));

  float bands = 0.0;
  bands += 0.5 * (sin(dist * 40.0) * 0.5 + 0.5);
  bands += 0.3 * (sin(dist * 65.0 + 2.0) * 0.5 + 0.5);
  bands += 0.2 * (sin(dist * 100.0 + 5.0) * 0.5 + 0.5);

  float gap1 = 1.0 - smoothstep(0.0, 0.015, abs(dist - 0.72));
  float gap2 = 1.0 - smoothstep(0.0, 0.01, abs(dist - 0.85));
  bands *= (1.0 - gap1 * 0.7) * (1.0 - gap2 * 0.8);

  float brightness = ring * bands;
  vec3 col = RingColor * brightness;

  float fade = 1.0 - abs(uv.y) * 1.5;
  fade = clamp(fade, 0.0, 1.0);

  gl_FragColor = vec4(col, brightness * fade * 0.7);
}
]]

-- ============================================================
-- MODULE: Pre-compile and manage shaders
-- ============================================================
local _sunShader = nil
local _planetShader = nil
local _ringShader = nil
local _supported = false

function Shaders.init()
  local ok1, s1 = pcall(lgNewShader, VERT_SRC, SUN_FRAG)
  local ok2, s2 = pcall(lgNewShader, VERT_SRC, PLANET_FRAG)
  local ok3, s3 = pcall(lgNewShader, VERT_SRC, RING_FRAG)

  _sunShader = ok1 and s1 or nil
  _planetShader = ok2 and s2 or nil
  _ringShader = ok3 and s3 or nil
  _supported = ok1 and ok2 and ok3

  return _supported
end

function Shaders.isSupported()
  return _supported
end

-- ============================================================
-- SUN DRAWING
-- ============================================================
local _sunColorBuf = {0, 0, 0}

function Shaders.drawSun(x, y, radius, color, intensity, time, seed)
  if not _sunShader then return end
  lg.setShader(_sunShader)
  _sunColorBuf[1], _sunColorBuf[2], _sunColorBuf[3] = color[1], color[2], color[3]
  _sunShader:send("Time", time)
  _sunShader:send("StarColor", _sunColorBuf)
  _sunShader:send("Intensity", intensity or 1.0)
  _sunShader:send("StarSeed", seed or 0)
  lg.setColor(1, 1, 1, 1)
  lg.rectangle("fill", x - radius, y - radius, radius * 2, radius * 2)
  lg.setShader(nil)
end

-- ============================================================
-- PLANET DRAWING
-- ============================================================
local _planetColorBuf = {0, 0, 0}
local _planetColor2Buf = {0, 0, 0}

function Shaders.drawPlanet(x, y, radius, color1, color2, planetType, hasAtmo, time, seed)
  if not _planetShader then return end
  lg.setShader(_planetShader)
  _planetColorBuf[1], _planetColorBuf[2], _planetColorBuf[3] = color1[1], color1[2], color1[3]
  _planetColor2Buf[1], _planetColor2Buf[2], _planetColor2Buf[3] = color2[1], color2[2], color2[3]
  _planetShader:send("PlanetColor", _planetColorBuf)
  _planetShader:send("PlanetColor2", _planetColor2Buf)
  _planetShader:send("PlanetType", planetType or 0)
  _planetShader:send("HasAtmosphere", hasAtmo and 1.0 or 0.0)
  _planetShader:send("PlanetSeed", seed or 0)
  _planetShader:send("Time", time or 0)
  lg.setColor(1, 1, 1, 1)
  lg.rectangle("fill", x - radius, y - radius, radius * 2, radius * 2)
  lg.setShader(nil)
end

-- ============================================================
-- RING DRAWING
-- ============================================================
local _ringColorBuf = {0, 0, 0}

function Shaders.drawRing(x, y, innerR, outerR, color, seed)
  if not _ringShader then return end
  local size = outerR * 2.2
  lg.setShader(_ringShader)
  _ringColorBuf[1], _ringColorBuf[2], _ringColorBuf[3] = color[1], color[2], color[3]
  _ringShader:send("RingColor", _ringColorBuf)
  _ringShader:send("PlanetSeed", seed or 0)
  lg.setColor(1, 1, 1, 1)
  lg.rectangle("fill", x - size, y - size, size * 2, size * 2)
  lg.setShader(nil)
end

return Shaders
