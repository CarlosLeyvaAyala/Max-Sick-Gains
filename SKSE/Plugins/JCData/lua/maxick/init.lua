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

---@alias Actor table<string, any>

-- ;>========================================================
-- ;>===                SAMPLE VARIABLES                ===<;
-- ;>========================================================

--- Dummy sliders used for testing algorithms.
local sampleSliders = {
  BreastFlatness = 0.1,
  BreastHeight = 0.45,
  ButtClassic = 0,
  Waist = 0,
  BellyFrontDownFat_v2 = 0,
  DummySlider = 1.0,
  ManyOtherSliders = 0
}


--- Same named variables as [sampleNPC](npc.lua) have the same function. No need to document.
local samplePlayer = {
  bodySlide = sampleSliders,
  isFem = 1,
  msg = "",
  muscleDefType = -1,
  muscleDef = -1,
  ---Used to know if muscle definition is banned for her race.
  raceEDID = "NordRace",
  --- Current Player stage.
  stage = 1,
  --- Training that will get converted to `gains`. `[0..12]`
  training = 12,
  --- Player stage completition value. `If >= 100`, go up. `If < 0`, go down. `[0..100]`
  gains = math.random(100),
  --- Calculated head size.
  ---@meta out
  headSize = 1.0,

  --;> Variables used to send mod events

  --- When changing player stage, tells how many stages went forward or back.
  evChangeStage = 0
}

-- ;>========================================================
-- ;>===              PUBLISHED FUNCTIONS               ===<;
-- ;>========================================================

maxick.ChangeNpcAppearance = npc.ChangeAppearance
maxick.ChangePlayerAppearance = player.ChangeAppearance
maxick.Train = sk.Train
maxick.OnSleep = player.OnSleep

function maxick.SlideshowNextStage(stage)
  if stage < #db.playerStages then return stage + 1
  else return -1
  end
end

function maxick.SlideshowStageMsg(stage) return player.LvlUpMessage(stage) end

-- ;>========================================================
-- ;>===                FUNCTION TESTING                ===<;
-- ;>========================================================

-- maxick.ChangePlayerAppearance(samplePlayer)
-- maxick.Train({skill = "SackL",training = 11.5, lastActive = 5})
-- samplePlayer.gains = 96
-- samplePlayer.training = 0.2
-- maxick.OnSleep(samplePlayer, 14)

-- print(maxick.SlideshowNextStage(1))
-- print(maxick.SlideshowStageMsg(3))
return maxick
