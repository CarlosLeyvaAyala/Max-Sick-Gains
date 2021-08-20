-- package.path = package.path..";F:/Skyrim SE/MO2/mods/DM-SkyrimSE-Library/SKSE/Plugins/JCData/lua/?/init.lua"
-- package.path = package.path..";F:/Skyrim SE/MO2/mods/JContainers SE/SKSE/Plugins/JCData/lua/?/init.lua"
-- package.path = package.path..";F:/Skyrim SE/MO2/mods/Max Sick Gains/SKSE/Plugins/JCData/lua/maxick/?.lua"
-- package.path = package.path..";F:/Skyrim SE/MO2/mods/Max-Sick-Gains-src/SKSE/Plugins/JCData/lua/maxick/?.lua"

local npc = jrequire 'maxick.npc'
local player = jrequire 'maxick.player'
local db = jrequire 'maxick.database'
local sk = jrequire 'maxick.skill'

local maxick = {}
math.randomseed( os.time() )

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

--- Table structure for visually processing NPCs.
--- This is a dummy variable used only for reference.
local sampleNPC = {
  --- Actor name. Used to try to find it in the known npcs database.
  name = "Lydia",
  --- Used to try to find it in the known npcs database.
  formId = 666766,
  --- Gotten by Lua. Used to apply MCM settings based on NPC type.
  isKnown = 0,
  --- Additional info of the operation. This is output to the Skyrim console.
  msg = "",
  --- Sex is gotten from in game, not the master esp, in case the player had
  --- installed a mod that makes everyone women or something.
  --- This selects the Bodyslide preset used.
  isFem = 1,
  --- Not a Bodyslide preset, but the slider data that will be applied to an actor.
  --- Actual Bodyslide presets are taken from `database.lua`.
  bodySlide = sampleSliders,
  --- Used to calculate body slider values. Range: `[0..100]`.
  --- Either user assigned in Known NPCs or gotten from the game.
  weight = math.random(100),
  --- Used to determine Bodyslide preset and muscle definition. Created by player.
  fitStage = 1,
  --- What kind of muscle definition the `Actor` has. Since it relies on Armors and SetSkin()
  --- it is advisable to disable for some kind of races.
  --- * `-1`: Don't change muscle definition.
  --- * `0`: Plain looking. Average looking textures.
  --- * `1`: Fit looking. Athletic. Use ripped textures.
  --- * `2`: Fat. Actual average looks in real life (at least in my country). Use flabby textures.
  muscleDefType = -1,
  --- `[-1 to 6]`.
  --- * `-1` is "disabled"
  --- * `0` sets an armor with a variable texture list to dinamically change muscle definition
  --- based on weight.
  --- * `1-6` force that muscle definition on actor.
  muscleDef = -1,
  --- Actor race as registered in the esp file.
  raceEDID = "NordRace",
  --- Result from detecting if the race is known. Used for muscle definition.
  racialGroup = "",
  --- Used to print to the Skyrim console which race was matched in `database.races`.
  raceDisplay = "",
  --- Class name as gotten from PapyrusUtil.
  class = "Warrior",
  --- Wether to process the `Actor` at all. Always `false` for unknown races.
  shouldProcess = 0
}

--- Same named variables as sampleNPC have the same function. No need to document.
local samplePlayer = {
  bodySlide = sampleSliders,
  isFem = 1,
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

maxick.ProcessNPC = npc.ProcessNPC
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

-- maxick.ProcessNPC(sampleNPC)
-- maxick.ChangePlayerAppearance(samplePlayer)
-- maxick.Train({skill = "SackL",training = 11.5, lastActive = 5})
-- samplePlayer.gains = 96
-- samplePlayer.training = 0.2
-- maxick.OnSleep(samplePlayer, 14)

-- print(maxick.SlideshowNextStage(1))
-- print(maxick.SlideshowStageMsg(3))
return maxick
