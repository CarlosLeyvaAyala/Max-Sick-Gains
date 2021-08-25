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

local maxick = {}
math.randomseed( os.time() )

---@alias Sex
---|'0'
---|'1'

---@alias SkyrimHours number Hours as fractions of a day.
---@alias HumanHours number Hours as numbers in a day.

-- ;>========================================================
-- ;>===              PUBLISHED FUNCTIONS               ===<;
-- ;>========================================================

maxick.ChangeNpcAppearance = npc.ChangeAppearance
maxick.InitWidget = widget.Init

maxick.ChangePlayerAppearance = player.ChangeAppearance
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
