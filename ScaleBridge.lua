-- STUFF YOU CAN CHANGE --

--path to FoxCamera, if installed, wherever its installed. Dont change if not installed
local FOXCameraPath = "lib.FOXCamera"
--group thats scaled
  local ScaledGroup = models.Moth.centerpoint
--Scale down, when NBTScale on init is 1 (Only applies on init)
  local NoNBTScale = 0.8
--Scale of the model, use for when you want to always scale down your model a certain amount
  local BaseScale = 0.93
--Do you want the action wheel?
  local ActionWheelToggle = true

-- DONT TOUCH BEYOND HERE --

--Checks if FoxCamera is installed
local foxCameraInstalled = false
local commandLibInstalled = false
if host:isHost() then
  for _, v in ipairs(listFiles(nil, true)) do
    if v:lower():find("foxcamera") then foxCameraInstalled = true end
    if v:lower():find("commandlib") then commandLibInstalled = true end
  end
end

if foxCameraInstalled == false and host:isHost() then
  printJson(toJson({ text = "Hey, this script doesn’t change the camera position — please use FoxCamera to move the camera if wanted.", color = "red" }))
else
  local FOXCamera = require(FOXCameraPath)
  --FoxCamera's camera object
  local Camera = FOXCamera.getCamera()
end

local ScriptScale = 1
local TrueScale = 1
local NBTScale = 1           --Scale from NBT (1.20.5+)
local ModelScale = 1 

--on init
ScaledGroup:setScale(BaseScale)

local delayedInitToggle = true
local delayedInit = 0

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
    --tick_counter = 400       --force tick
    ScaledGroup:setScale(ScriptScale)
  end
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

--custom initDelay, I dont know why it exists anymore, but it breaks otherwise...
local onInit = true
local tick_counter = 200
function events.tick()
  tick_counter = tick_counter + 1
  if tick_counter >= 200/5 then
    tick_counter = 0

    --calculate NBTScale on host only, FoxCamera is active and in use, and only if the host is on 1.20.5 or beyond
    if host:isHost() and (client.compareVersions(client:getVersion(), '1.20.5') ~= -1) then
      --print(fixFoxCamearScale(FOXCamera.attributes.scale))
      NBTScale = roundNBTScale(player:getBoundingBox().x / 0.6)
    end

    --if NBTScale cannot be changed, or isnt changed, set ScriptScale to NoNBTScale on init
    if onInit and NBTScale == 1 and host:isHost() then
      ScriptScale = NoNBTScale
      onInit = false
    end

    --pings the NBTScale
    pings.NBTScale(NBTScale)
    pings.ScriptScale(ScriptScale, false)

    --TrueScale is the total of NBTScale and ModelScale
    TrueScale = NBTScale * BaseScale * ScriptScale

    ModelScale = BaseScale * ScriptScale

    --makes sure the camera works nicely, I hope
    if foxCameraInstalled and host:isHost() then
      MyCamera.scale = ModelScale
    end

    --ScaleBridge
    if (client.compareVersions(client:getVersion(), '1.20.5') ~= -1) then
      ScaledGroup:setScale(ModelScale)
    else
      ScaledGroup:setScale(TrueScale)
    end

    renderer:setShadowRadius(TrueScale*0.5)
    nameplate.ENTITY:setPivot(0, ((2 * TrueScale) + (TrueScale*0.3) + 0.15), 0)
    nameplate.ENTITY:setScale(TrueScale)


    avatar:store("patpat.boundingBox", (player:getBoundingBox() * NBTScale))

  end
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
    :setOnLeftClick(function()
      clickSound:setPitch(1):stop():play()
      ScriptScale = 1
      ScaledGroup:setScale(BaseScale)
      HostChangeScale()
    end)
    :setOnRightClick(function()
      clickSound:setPitch(1):stop():play()
      ScriptScale = 1
      ScaledGroup:setScale(BaseScale)
      HostChangeScale()
    end)
    :onScroll(function(dir, self)
      clickSound:setPitch(1):stop():play()
      if dir > 0 then
        ScriptScale = math.clamp(ScriptScale+0.025, 0.075, math.huge)
      else
        ScriptScale = math.clamp(ScriptScale-0.025, 0.075, math.huge)
      end
      self:title("Scale - " .. tostring(ScriptScale))
      ScaledGroup:setScale(BaseScale * ScriptScale)
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
      --print(ANumber)
    end)
end