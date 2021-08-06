-- package.path = package.path..";F:/Skyrim SE/MO2/mods/DM-SkyrimSE-Library/SKSE/Plugins/JCData/lua/?/init.lua"
-- package.path = package.path..";F:/Skyrim SE/MO2/mods/JContainers SE/SKSE/Plugins/JCData/lua/?/init.lua"
-- package.path = package.path..";F:/Skyrim SE/MO2/mods/Max Sick Gains/SKSE/Plugins/JCData/lua/maxick/?.lua"
-- package.path = package.path..";F:/Skyrim SE/MO2/mods/Max-Sick-Gains-src/SKSE/Plugins/JCData/lua/maxick/?.lua"

local npc = jrequire 'maxick.npc'

local maxick = {}

--- Table structure for visually processing NPCs.
--- This is a dummy variable used only for reference.
local sampleTable = {
  --- Actor name. Used to try to find it in the known npcs database.
  name = "Lydia",
  --- Used to try to find it in the known npcs database.
  -- formId = 666766,

  --- Gotten by Lua. Used to apply MCM settings based on NPC type.
  isKnown = false,
  --- Additional info of the operation. This is output to the Skyrim console.
  msg = "",
  --- Not a Bodyslide preset, but the slider data that will be applied to an actor.
  --- Actual Bodyslide presets are taken from `database.lua`.
  bodySlide = {
    BreastFlatness = 0.1,
    BreastFlatness2 = 1,
    BreastHeight = 0.45,
    ManyOtherSliders = 0
  },
  --- Sex is gotten from in game, not the master esp, in case the player had
  --- installed a mod that makes everyone women or something.
  --- This selects the Bodyslide preset used.
  isFem = true,
  --- Used to calculate body slider values.
  --- * If Player, this is the training value for her current fitness stage.
  --- * If NPC, weight; player assigned or gotten from the game.
  weight = 101,
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
  raceEDID = "NordRaceVampire",
  --- Result from getting an `Actor` race. Used to get which appearance the NPC should have.
  --- Always taken from `database.races`.
  race = "",
  --- Result from detecting if the race is known. Used for muscle definition.
  racialGroup = "",
  --- Used to print to the SKyrim console which race was matched in `database.races`.
  raceDisplay = "",
  --- Wether to process the `Actor` at all. Always `false` for unknown races.
  shouldProcess = false
}

-- maxick.ProcessKnownNPC = npc.ProcessKnownNPC
-- maxick.ProcessUnknownNPC = npc.ProcessUnknownNPC
maxick.ProcessNPC = npc.ProcessNPC


maxick.ProcessNPC(sampleTable)

return maxick
