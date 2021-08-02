-- package.path = package.path..";F:/Skyrim SE/MO2/mods/DM-SkyrimSE-Library/SKSE/Plugins/JCData/lua/?/init.lua"
-- package.path = package.path..";F:/Skyrim SE/MO2/mods/JContainers SE/SKSE/Plugins/JCData/lua/?/init.lua"
-- package.path = package.path..";F:/Skyrim SE/MO2/mods/Max Sick Gains/SKSE/Plugins/JCData/lua/maxick/?.lua"
-- package.path = package.path..";F:/Skyrim SE/MO2/mods/Max-Sick-Gains-src/SKSE/Plugins/JCData/lua/maxick/?.lua"

local npc = jrequire 'maxick.npc'

local maxick = {}

maxick.ProcessKnownNPC = npc.ProcessKnownNPC

-- local test = {
--   bodySlide = {
--     BreastFlatness = 0.1,
--     BreastFlatness2 = 1,
--     BreastHeight = 0.45
--   },
--   isFem = true,
--   msg = "",
--   weight = 40,
--   shouldProcess = true,
--   fitStage = 5,
--   muscleDef = 6
-- }

-- maxick.ProcessKnownNPC(test)

return maxick
