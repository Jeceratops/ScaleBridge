--Scalebridge!
--Version 0.2_1
--[[
        CREDITS
        Jceratops (Jcera): ScaleBridge (This script!)
        Bitslayn: Modular Action Wheel
        Xander: Recursive Script Search, Redundant Code Removal, Interpolation
]]--

-- STUFF YOU CAN CHANGE --

--Path to FoxCamera
  local FOXCamera
--Model Group to Scale
  local ScaledGroup = models.model.root
--Scale down, when NBTScale on init is 1 (Only applies on init)
  local NoNBTScale = 1
--Scale of the model, use for when you want to always scale down your model a certain amount
  local BaseScale = 1
--Nameplate offset customization, its really a crapshoot to customize, so... if you dont like it, screw with the value!
  local NameplateOffset = 1.5
--Do you want the action wheel?
  local ActionWheelToggle = true
--Show or Hide Warnings and/or Custom Errors
  local debug = false
--Set Interpolation Speed
  local lerpSpeed = 0.5 --change as desired

-- [[DONT TOUCH BEYOND HERE]] --

--Checks if FoxCamera is installed
local foxCameraInstalled = false
local commandLibInstalled = false
for _, key in ipairs(listFiles(nil, true)) do --Recursively find FOXCamera
  local formatted = string.lower(key)
  if formatted:find("foxcamera$") then
    FOXCamera = require(key) 
    foxCameraInstalled = true
  else --no FOXCamera?
    if host:isHost() and debug then
      printJson(toJson({ text = "Hey, this script doesn't change the camera position — please use FoxCamera to move the camera if desired.", color = "red" }))
    end
  end
  if formatted:find("commandlib$") then
    commandLibInstalled = true
  end
end
local lerp = math.lerp
local ScriptScale = 1
local TrueScale = 1
local NBTScale = 1           --Scale from NBT (1.20.5+)
local ModelScale = 1
local _FinalScale, FinalScale = 1, 1
local selScale = ModelScale
local MyCamera = FOXCamera.getCamera() --get current camera
--on init
ScaledGroup:setScale(BaseScale)

local delayedInitToggle = true
local delayedInit = 0
local onInit = true
local tick_counter = 200

--does what it says on the tin (rounds to nearest ten thousandth)
local function roundNBTScale(var)
  return math.floor(var * 10000 + 0.5) / 10000
end

-- Pings and useful returns --

function pings.NBTScale(var)
  NBTScale = var
end

function pings.TrueScale(var)
  TrueScale = var
end

function pings.ScriptScale(var, isHost)
  ScriptScale = var
  if isHost then
    ScaledGroup:setScale(ScriptScale)
  end
end

function pings.syncLerpSpeed(x)
  lerpSpeed = x
end

local function HostChangeScale()
  ModelScale = BaseScale * ScriptScale
  if foxCameraInstalled then
    MyCamera.scale = ModelScale
  end
end

function GetNBTScale()
  return NBTScale
end

function GetTrueScale()
  return TrueScale
end

function GetModelScale()
  return ModelScale
end

function SetLerpSpeed(x)
  lerpSpeed = x
  pings.syncLerpSpeed(x)
end

--custom initDelay, I dont know why it exists anymore, but it breaks otherwise...

function events.tick()
  _FinalScale = FinalScale
  tick_counter = tick_counter + 1
  if tick_counter >= 200/5 then
    tick_counter = 0
    --pings the NBTScale
    pings.NBTScale(NBTScale)
    pings.ScriptScale(ScriptScale, false)
    pings.syncLerpSpeed(lerpSpeed)
  end
    --calculate NBTScale on host only, FoxCamera is active and in use, and only if the host is on 1.20.5 or beyond
  if host:isHost() and (client.compareVersions(client:getVersion(), '1.20.5') ~= -1) then
    NBTScale = roundNBTScale(player:getBoundingBox().x / 0.6)
  end

  --if NBTScale cannot be changed, or isnt changed, set ScriptScale to NoNBTScale on init
  if onInit and NBTScale == 1 and host:isHost() then
    ScriptScale = NoNBTScale
    onInit = false
  end

    --TrueScale is the total of NBTScale and ModelScale
  TrueScale = NBTScale * BaseScale * ScriptScale

  ModelScale = BaseScale * ScriptScale

  --makes sure the camera works nicely, I hope
  if foxCameraInstalled and host:isHost() then
    MyCamera.scale = ModelScale
  end

  renderer:setShadowRadius(TrueScale*0.5) --Set Shadow Radius
  nameplate.ENTITY:setPivot(0, (TrueScale + (TrueScale*NameplateOffset)), 0) --set Nameplate Pivot
  nameplate.ENTITY:setScale(TrueScale) --set nameplate scale
  avatar:store("patpat.boundingBox", (player:getBoundingBox() * NBTScale)) --store patpat AABB

  --ScaleBridge
  if (client.compareVersions(client:getVersion(), '1.20.5') ~= -1) then
      selScale = ModelScale
  else
      selScale = TrueScale
  end
    FinalScale = lerp(FinalScale, selScale, lerpSpeed)
end

local renderScale = 1
function events.render(delta)
  renderScale = lerp(_FinalScale, FinalScale, delta)
  ScaledGroup:setScale(renderScale)
end

--Action Wheel
if host:isHost() and ActionWheelToggle then
  function events.entity_init()
  
  --borrowed from Fox, with her permission
  local actionWheel = action_wheel:getCurrentPage() or action_wheel:newPage("mainPage")
  if not action_wheel:getCurrentPage() then
    action_wheel:setPage("mainPage")
  end

  local clickSound = sounds["minecraft:ui.button.click"]:setVolume(0.2)

  actionWheel:newAction()
    :title("Scale - " .. tostring(ScriptScale))
    :setItem("minecraft:piston")
    :setOnLeftClick(function(self)
      clickSound:setPitch(1):stop():play()
      ScriptScale = 1
      HostChangeScale()
      self:title("Scale - " .. tostring(ScriptScale))
    end)
    :setOnRightClick(function(self)
      clickSound:setPitch(1):stop():play()
      ScriptScale = 1
      HostChangeScale()
      self:title("Scale - " .. tostring(ScriptScale))
    end)
    :onScroll(function(dir, self)
      clickSound:setPitch(1):stop():play()
      if dir > 0 then
        ScriptScale = math.clamp(ScriptScale+0.025, 0.075, math.huge)
      else
        ScriptScale = math.clamp(ScriptScale-0.025, 0.075, math.huge)
      end
      self:title("Scale - " .. tostring(ScriptScale))
      selScale = BaseScale * ScriptScale
      HostChangeScale()
    end)
  end
end

if host:isHost() and commandLibInstalled then
local scaleCommand = commands
    :createCommand("scale")
    :setFunction(function(var)
      ScriptScale = var
      pings.ScriptScale(var, true)
    end)

end








