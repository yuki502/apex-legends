local Object = require("lib.classic")

local lg = love.graphics
local lgNewShader = lg.newShader

local Shader = Object:extend()

local MAX_LIGHTS = 8

local LIGHT_POS_NAMES = {}
local LIGHT_COLOR_NAMES = {}
local LIGHT_INT_NAMES = {}
for i = 0, 7 do
  LIGHT_POS_NAMES[i] = "LightPos[" .. i .. "]"
  LIGHT_COLOR_NAMES[i] = "LightColor[" .. i .. "]"
  LIGHT_INT_NAMES[i] = "LightIntensity[" .. i .. "]"
end

local VERT_SRC = [[
varying vec2 v_texCoord;

#ifdef GL_ES
precision mediump float;
#endif

attribute vec2 VertexPosition;
attribute vec2 VertexTexCoord;

uniform vec2 ScreenSize;

void main() {
  v_texCoord = VertexTexCoord;
  vec2 pos = VertexPosition;
  gl_Position = vec4(pos, 0.0, 1.0);
}
]]

local FRAG_SRC = [[
#ifdef GL_ES
precision mediump float;
#endif

varying vec2 v_texCoord;

uniform float Time;
uniform vec2 ScreenSize;
uniform vec2 CameraOffset;

uniform int LightCount;
uniform vec3 LightPos[8];
uniform vec3 LightColor[8];
uniform float LightIntensity[8];
uniform float AmbientLight;

uniform float ParallaxSpeed;
uniform float VignetteStrength;
uniform float ColorTemp;
uniform sampler2D MainTex;

float hash(vec2 p) {
  return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
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
  for (int i = 0; i < 4; i++) {
    v += a * noise(p);
    p = p * 2.0 + shift;
    a *= 0.5;
  }
  return v;
}

vec4 parallaxLayer(float depth, vec2 uv, float t) {
  vec2 scroll = uv + vec2(0.0, t * ParallaxSpeed * depth);
  float n = fbm(scroll * (2.0 + depth * 3.0));
  float stars = step(0.98, hash(floor(scroll * 80.0)));
  vec3 baseColor = mix(vec3(0.02, 0.02, 0.06), vec3(0.05, 0.03, 0.12), n);
  float brightness = mix(0.3, 1.0, stars) * (1.0 - depth * 0.4);
  return vec4(baseColor * brightness, (1.0 - depth) * 0.35);
}

vec3 computeLighting(vec3 baseColor, vec2 fragPos) {
  vec3 totalLight = vec3(AmbientLight * 0.15);
  for (int i = 0; i < 8; i++) {
    if (i >= LightCount) break;
    vec2 delta = LightPos[i].xy - fragPos;
    float distSq = dot(delta, delta);
    float att = LightIntensity[i] / (distSq + 1.0);
    totalLight += LightColor[i] * att;
  }
  return baseColor * clamp(totalLight, 0.0, 2.0);
}

vec3 applyVignette(vec3 color, vec2 uv) {
  vec2 centered = uv - 0.5;
  float dist = dot(centered, centered);
  float vig = 1.0 - dist * VignetteStrength;
  return color * clamp(vig, 0.0, 1.0);
}

vec3 applyColorGrading(vec3 color) {
  color.r *= 1.0 + ColorTemp * 0.05;
  color.b *= 1.0 - ColorTemp * 0.03;
  color = pow(color, vec3(0.95));
  return color;
}

void main() {
  vec2 uv = v_texCoord;
  vec4 sceneColor = texture2D(MainTex, uv);

  vec2 screenPos = uv * ScreenSize;
  vec2 scrollUV = (screenPos + CameraOffset) / ScreenSize;

  vec4 layer1 = parallaxLayer(0.0, scrollUV, Time);
  vec4 layer2 = parallaxLayer(0.25, scrollUV, Time);
  vec4 layer3 = parallaxLayer(0.5, scrollUV, Time);
  vec4 layer4 = parallaxLayer(0.75, scrollUV, Time);
  vec4 layer5 = parallaxLayer(1.0, scrollUV, Time);

  vec3 parallaxColor = layer1.rgb * layer1.a;
  parallaxColor += layer2.rgb * layer2.a;
  parallaxColor += layer3.rgb * layer3.a;
  parallaxColor += layer4.rgb * layer4.a;
  parallaxColor += layer5.rgb * layer5.a;

  vec3 finalColor = mix(parallaxColor, sceneColor.rgb, sceneColor.a * 0.85 + 0.15);

  finalColor = computeLighting(finalColor, screenPos);
  finalColor = applyVignette(finalColor, uv);
  finalColor = applyColorGrading(finalColor);

  gl_FragColor = vec4(finalColor, 1.0);
}
]]

function Shader:new()
  self._shader = nil
  self._supported = false
  self.time = 0
  self.cameraX = 0
  self.cameraY = 0
  self.lightCount = 0
  self.lights = {}
  for i = 1, MAX_LIGHTS do
    self.lights[i] = { x = 0, y = 0, r = 0, g = 0, b = 0, i = 0 }
  end
  self._camBuf = { 0, 0 }
  self._posBuf = { 0, 0, 0 }
  self._colorBuf = { 0, 0, 0 }
  self.ambientLight = 0.3
  self.parallaxSpeed = 12.0
  self.vignetteStrength = 1.8
  self.colorTemp = 0.5
  self:_init()
end

function Shader:_init()
  if not lgNewShader then
    self._supported = false
    return
  end
  local ok, shader = pcall(lgNewShader, VERT_SRC, FRAG_SRC)
  if ok and shader then
    self._shader = shader
    self._supported = true
    self:_sendStaticUniforms()
  else
    self._supported = false
  end
end

function Shader:_sendStaticUniforms()
  if not self._supported then return end
  local s = self._shader
  self._camBuf[1] = love.graphics.getWidth()
  self._camBuf[2] = love.graphics.getHeight()
  s:send("ScreenSize", self._camBuf)
  s:send("ParallaxSpeed", self.parallaxSpeed)
  s:send("VignetteStrength", self.vignetteStrength)
  s:send("ColorTemp", self.colorTemp)
  s:send("AmbientLight", self.ambientLight)
end

function Shader:update(dt)
  self.time = self.time + dt
end

function Shader:setCamera(x, y)
  self.cameraX = x
  self.cameraY = y
end

function Shader:addLight(x, y, r, g, b, intensity)
  if self.lightCount >= MAX_LIGHTS then return end
  self.lightCount = self.lightCount + 1
  local l = self.lights[self.lightCount]
  l.x, l.y, l.r, l.g, l.b, l.i = x, y, r, g, b, intensity or 1.0
end

function Shader:clearLights()
  self.lightCount = 0
end

function Shader:apply()
  if not self._supported then return end
  local s = self._shader
  lg.setShader(s)

  s:send("Time", self.time)
  self._camBuf[1] = self.cameraX
  self._camBuf[2] = self.cameraY
  s:send("CameraOffset", self._camBuf)

  local count = self.lightCount
  s:send("LightCount", count)

  for i = 1, count do
    local l = self.lights[i]
    local idx = i - 1
    self._posBuf[1], self._posBuf[2], self._posBuf[3] = l.x, l.y, 0
    s:send(LIGHT_POS_NAMES[idx], self._posBuf)
    self._colorBuf[1], self._colorBuf[2], self._colorBuf[3] = l.r, l.g, l.b
    s:send(LIGHT_COLOR_NAMES[idx], self._colorBuf)
    s:send(LIGHT_INT_NAMES[idx], l.i)
  end
  for i = count + 1, MAX_LIGHTS do
    s:send(LIGHT_INT_NAMES[i - 1], 0)
  end
end

function Shader:remove()
  lg.setShader(nil)
end

function Shader:isSupported()
  return self._supported
end

return Shader
