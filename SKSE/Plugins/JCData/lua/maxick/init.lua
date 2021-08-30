-- package.path = package.path..";F:/Skyrim SE/MO2/mods/DM-SkyrimSE-Library/SKSE/Plugins/JCData/lua/?/init.lua"
-- package.path = package.path..";F:/Skyrim SE/MO2/mods/JContainers SE/SKSE/Plugins/JCData/lua/?/init.lua"
-- package.path = package.path..";F:/Skyrim SE/MO2/mods/Max Sick Gains/SKSE/Plugins/JCData/lua/maxick/?.lua"
-- package.path = package.path..";F:/Skyrim SE/MO2/mods/Max-Sick-Gains-src/SKSE/Plugins/JCData/lua/maxick/?.lua"

local l = jrequire 'dmlib'
local npc = jrequire 'maxick.npc'
local player = jrequire 'maxick.player'
local db = jrequire 'maxick.database'
local sk = jrequire 'maxick.skill'
local ml = jrequire 'maxick.lib'
local widget = jrequire 'maxick.reportWidget'
local gc = jrequire 'maxick.genConst'

local maxick = {}
math.randomseed( os.time() )

---@alias Sex
---|'0'
---|'1'

---@alias MuscleDef
---|'-1' Don't apply
---|'0' Use Skin texture swap list. Weight based.
---|'1'
---|'2'
---|'3'
---|'4'
---|'5'
---|'6'

---@alias MuscleDefType
---|'-1' Don't apply
---|'0' Plain
---|'1' Fit
---|'2' Fat

---@alias BodyslidePreset table<string, number> Calculated preset that will be applied.
---@alias SkyrimHours number Hours as fractions of a day.
---@alias HumanHours number Hours as numbers in a day.
---@alias LoggingFunc fun(message: string)

-- ;>========================================================
-- ;>===              PUBLISHED FUNCTIONS               ===<;
-- ;>========================================================

maxick.HAlign = gc.HAlign
maxick.VAlign = gc.VAlign

maxick.WidgetMeterPositions = l.toJMap(widget.MeterPositions)

maxick.ChangeNpcAppearance = l.toJMap(npc.ChangeAppearance)

maxick.ChangePlayerAppearance = l.toJMap(player.ChangeAppearance)
maxick.OnSleep = l.toJMap(player.OnSleep)
maxick.Poll = l.toJMap(player.Polling)
maxick.trainingDecay = player.trainingDecay
maxick.HadActivity = player.HadActivity
maxick.CapTraining = player.CapTraining

maxick.Train = l.toJMap(sk.Train)

---Advances to next stage while in testing mode.
---@param stage number
---@return number
function maxick.SlideshowNextStage(stage)
  if stage < #db.playerStages then return stage + 1
  else return -1
  end
end

---Shows the _"next stage reached"_ message while in slideshow mode.
---@param stage number
---@return string
function maxick.SlideshowStageMsg(stage) return player.StageMessage(stage) end

return maxick
