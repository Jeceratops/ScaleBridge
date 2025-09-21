--Scalebridge!
--Version 0.2.7
--[[
        CREDITS
        Jceratops (Jcera): ScaleBridge (This script!)
        Bitslayn: Modular Action Wheel
        Xander: Recursive Script Search, Redundant Code Removal, Interpolation
]]--


--#region 'Configure'

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

--Advanced
  local commandLibOverride = true

--#endregion


--#region 'Don't Touch (Unless you're 5Head)'

--#region 'Dependencies'
local foxCameraInstalled = false
local commandLibInstalled = false
local isclib_local = false
local sendWarnOnce = false
for _, key in ipairs(listFiles(nil, true)) do --Recursively find FOXCamera
  local formatted = string.lower(key)
  if formatted:find("foxcamera$") then
    FOXCamera = require(key) 
    foxCameraInstalled = true
  else --no FOXCamera?
    if host:isHost() and debug then
      if not sendWarnOnce then
        sendWarnOnce = true
        printJson(toJson({ text = "Hey, this script doesn't change the camera position — please use FoxCamera to move the camera if desired.", color = "red" }))
      end
    end
  end
    isclib_local = ((not formatted:find("commandlib$")) and commands)
    commandLibInstalled = (not commandLibOverride) and (isclib_local or formatted:find("commandlib$"))
    --log(commandLibInstalled)
end
--#endregion

--#region 'Setup'
local lerp = math.lerp
local MyCamera
local clickSound = host:isHost() and sounds["minecraft:ui.button.click"]:setVolume(0.2) or nil
local ScriptScale = 1
local TrueScale = 1
local NBTScale = 1           --Scale from NBT (1.20.5+)
local ModelScale = 1
local selScale = ModelScale
local _FinalScale, FinalScale = 1, 1
local renderScale = 1
local tick_counter = 200
local ScaleHelperInstalled = false

function events.entity_init() --because it needs to be delayed
  MyCamera = FOXCamera.getCamera()
  ScaledGroup:setScale(BaseScale)
    if client.isModLoaded("pehkui") then 
      host:sendChatCommand("/sh")
      events.CHAT_RECEIVE_MESSAGE:register(function(msg) 
          if msg == "ScaleHelper exists :3" then 
            ScaleHelperInstalled = true 
          end
        end, 
      "ae")
      events.CHAT_RECEIVE_MESSAGE:remove("ae")
    end
end
--#endregion

--#region 'Local Functions'
--does what it says on the tin (rounds to nearest ten thousandth)
local function roundNBTScale(var)
  return math.floor(var * 10000 + 0.5) / 10000
end

local function HostChangeScale()
  ModelScale = BaseScale * ScriptScale
  if foxCameraInstalled then
    MyCamera.scale = ModelScale
  end
end


local function PekhuiScale(scale)
  if client.isModLoaded("pehkui") then
      host:sendChatCommand("/scale set pehkui:hitbox_width " .. scale)
      host:sendChatCommand("/scale set pehkui:hitbox_height " .. scale)
      host:sendChatCommand("/scale set pehkui:eye_height " .. scale)
      host:sendChatCommand("/scale set pehkui:view_bobbing " .. scale)  
  end
end
--#endregion


--#region 'Pings and Return Functions'
---@param var integer|number
function pings.NBTScale(var)
  NBTScale = var
end

---@param var integer|number
function pings.TrueScale(var)
  TrueScale = var
end

---@param var integer|number
---@param isHost boolean
function pings.ScriptScale(var, isHost)
  ScriptScale = var
  if isHost then
    ScaledGroup:setScale(ScriptScale)
  end
end

---@param x integer|number
function pings.syncLerpSpeed(x)
  lerpSpeed = x
end

---@return integer|number
function GetNBTScale()
  return NBTScale
end

---@return integer|number
function GetTrueScale()
  return TrueScale
end

---@return integer|number
function GetModelScale()
  return ModelScale
end

---@param x integer|number
function SetLerpSpeed(x)
  lerpSpeed = x
  pings.syncLerpSpeed(x)
end

---@param scale integer|number
function _PekhuiScale(scale)
  PekhuiScale(scale)
end
--#endregion

local triggeredOnce = false
function events.tick()
  _FinalScale = FinalScale
  tick_counter = tick_counter + 1
  if tick_counter >= 200/5 then
    tick_counter = 0
    --Execute Pings
    pings.NBTScale(NBTScale)
    pings.ScriptScale(ScriptScale, false)
    pings.syncLerpSpeed(lerpSpeed)
    if client.isModLoaded("pehkui") and ScaleHelperInstalled then 
      host:sendChatCommand("/sh hitboxscale " .. FinalScale)
    elseif client.isModLoaded("pehkui") and not ScaleHelperInstalled then 
        PekhuiScale(renderScale) 
    end

  end
    --calculate NBTScale on host only, FoxCamera is active and in use, and only if the host is on 1.20.5 or beyond
  if host:isHost() and (client.compareVersions(client:getVersion(), '1.20.5') ~= -1) then
    NBTScale = roundNBTScale(player:getBoundingBox().x / 0.6)
  end

  --if NBTScale cannot be changed, or isnt changed, set ScriptScale to NoNBTScale on init
  if NBTScale == 1 and host:isHost() and tick_counter == 39 and (not triggeredOnce) then
    ScriptScale = NoNBTScale
    triggeredOnce = true
  end

    --TrueScale is the total of NBTScale and ModelScale
  TrueScale = NBTScale * BaseScale * ScriptScale

  ModelScale = BaseScale * ScriptScale

  --makes sure the camera works nicely, I hope
  if foxCameraInstalled and host:isHost() then
      MyCamera.scale = ModelScale
  end
  avatar:store("patpat.boundingBox", (player:getBoundingBox() * NBTScale)) --store patpat AABB

  --ScaleBridge
  selScale = (client.compareVersions(client:getVersion(), '1.20.5') ~= -1) and ModelScale or TrueScale
  FinalScale = lerp(FinalScale, selScale, lerpSpeed)
end


function events.render(delta)
  renderScale = lerp(_FinalScale, FinalScale, delta)
  ScaledGroup:setScale(renderScale)

  --crouch fix?
  if player:isCrouching() then ScaledGroup:setPos(0,-2.3 * 0.075+ 2.3,0) else ScaledGroup:setPos(0,0,0) end

  renderer:setShadowRadius(renderScale*0.5) --Set Shadow Radius
  nameplate.ENTITY:setPivot(0, (renderScale + (renderScale*NameplateOffset)), 0) --set Nameplate Pivot
  nameplate.ENTITY:setScale(renderScale) --set nameplate scale
end

--#region 'Action Wheel'
if host:isHost() and ActionWheelToggle then
  function events.entity_init()
  --borrowed from Fox, with her permission
  local actionWheel = action_wheel:getCurrentPage() or action_wheel:newPage("mainPage")
  if not action_wheel:getCurrentPage() then
    action_wheel:setPage("mainPage")
  end

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
--#endregion

--#endregion
