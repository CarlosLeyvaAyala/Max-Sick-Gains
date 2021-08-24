-- package.path = package.path..";F:/Skyrim SE/MO2/mods/DM-SkyrimSE-Library/SKSE/Plugins/JCData/lua/?/init.lua"
-- package.path = package.path..";F:/Skyrim SE/MO2/mods/JContainers SE/SKSE/Plugins/JCData/lua/?/init.lua"
-- package.path = package.path..";F:/Skyrim SE/MO2/mods/Max Sick Gains/SKSE/Plugins/JCData/lua/maxick/?.lua"
-- package.path = package.path..";F:/Skyrim SE/MO2/mods/Max-Sick-Gains-src/SKSE/Plugins/JCData/lua/maxick/?.lua"

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

-- ;>========================================================
-- ;>===              PUBLISHED FUNCTIONS               ===<;
-- ;>========================================================

maxick.ChangeNpcAppearance = npc.ChangeAppearance
maxick.ChangePlayerAppearance = player.ChangeAppearance
maxick.Train = sk.Train
maxick.OnSleep = player.OnSleep
maxick.Progress = player.Progress
maxick.Regress = player.Regress
maxick.InitWidget = widget.Init

---Advances to next stage while in testing mode.
---@param stage number
---@return number
function maxick.SlideshowNextStage(stage)
  if stage < #db.playerStages then return stage + 1
  else return -1
  end
end

---Shows the _"next stage reached"_ message while in slideshow mode.
---@param stage any
---@return string
function maxick.SlideshowStageMsg(stage) return player.LvlUpMessage(stage) end

---Gets how much gains should be lost a day when in _Catabolic state_.
---@param stage number
---@return number
function maxick.GainsCatabolism(stage)
  return 1 / db.playerStages[stage].minDays * 0.8
end

return maxick
