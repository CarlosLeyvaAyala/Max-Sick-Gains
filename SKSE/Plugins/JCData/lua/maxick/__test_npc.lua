local test_npc = {}

local serpent = require("__serpent")
local npc = require 'npc'

require('lib').SetLoggingLvl(4)

local mcm = {
  all = {
    kNpcBs = 1,
    kNpcMuscleDef = 1,
    gNpcFemBs = 1,
    gNpcFemMuscleDef = 1,
    gNpcManBs = 1,
    gNpcManMuscleDef = 1,
  },
  none = {
    kNpcBs = 0,
    kNpcMuscleDef = 0,
    gNpcFemBs = 0,
    gNpcFemMuscleDef = 0,
    gNpcManBs = 0,
    gNpcManMuscleDef = 0,
  },
  noDef = {
    kNpcBs = 1,
    kNpcMuscleDef = 0,
    gNpcFemBs = 1,
    gNpcFemMuscleDef = 0,
    gNpcManBs = 1,
    gNpcManMuscleDef = 0,
  },
}

local Lydia = {
  --- MCM options from Papyrus
  mcm = mcm.all,
  --- Actor name. Used to try to find it in the known npcs database.
  name = "Lydia",
  --- Used to try to find it in the known npcs database.
  formId = 0xa2c8e,
  --- Used to calculate body slider values. Range: `[0..100]`.
  --- Either user assigned in Known NPCs or gotten from the game.
  weight = 100,
  --- Class name as gotten from PapyrusUtil.
  class = "Warrior",
  raceEDID = "NordRace",
  isFem = 1,
}

local meh = {
  mcm = mcm.all, name = "Meh",formId = 0, weight = math.random(100), class = "Bard", raceEDID = "KhajiitRace", isFem = 1
}
local meh2 = {
  mcm = mcm.all, name = "Meh",formId = 0, weight = math.random(100), class = "Assassin", raceEDID = "ArgonianRace", isFem = 1
}
local meh3 = {
  mcm = mcm.all, name = "Meh",formId = 0, weight = 100, class = "Citizen", raceEDID = "ArgonianRace", isFem = 1
}
local meh4 = {
  mcm = mcm.all, name = "",formId = 0, weight = 100, class = "Citizen", raceEDID = "SpiderRace", isFem = 0
}
local meh5 = {
  mcm = mcm.all, name = "",formId = 0, weight = 100, class = "OrcWarrior", raceEDID = "OrcRace", isFem = 1
}
local hulda = {
  mcm = mcm.all, name = "hulda", formId = 0x13ba3, weight = 19, class = "pawnbroker", raceEDID = "NordRace", isFem = 1
}

function test_npc.Run()
  serpent.print(npc.ChangeAppearance(Lydia))
  serpent.print(npc.ChangeAppearance(meh))
  serpent.print(npc.ChangeAppearance(meh2))
  serpent.print(npc.ChangeAppearance(meh3))
  serpent.print(npc.ChangeAppearance(meh4))
  Lydia.isFem = 0
  serpent.print(npc.ChangeAppearance(Lydia))
  serpent.print(npc.ChangeAppearance(meh5))
  serpent.print(npc.ChangeAppearance(hulda))
end

return test_npc
