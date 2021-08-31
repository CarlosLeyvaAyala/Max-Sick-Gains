--{RELEASE}

local skill = {}

local l = jrequire 'dmlib'
-- local serpent = require("__serpent")

--- Skills belong to `skillTypes`; each one representing a broad type of skills.
--- * `train` represents the relative contribution of the skill to training, and will be multiplied by the skill's own `train` contribution.
--- * `activity` is also a relative value. It represents how many days of `activity` this type of skill is worth.
skill.skillTypes = {
  phys = {train = 0.5, activity = 0.8},
  mag = {train = 0.1, activity = 0.3},
  sack = {train = 1, activity = 2},
  sex = {train = 0.005, activity = 0.2}
}

--- Represents a skill the player just leveled up.
--- * `skType` is the `skillTypes` each skill belongs to.
--- * `train` is the relative contribution of the skill to `training`.
--- * `activity` is the relative contribution in days of the skill to `activity`.
skill.skills ={
  TwoHanded = {skType = skill.skillTypes.phys, train = 1},
  OneHanded = {skType = skill.skillTypes.phys, train = 0.7},
  Block = {skType = skill.skillTypes.phys, train = 1},
  Marksman = {skType = skill.skillTypes.phys, train = 0.2},
  HeavyArmor = {skType = skill.skillTypes.phys, train = 1},
  LightArmor = {skType = skill.skillTypes.phys, train = 0.3},
  Sneak = {skType = skill.skillTypes.phys, train = 0.3},
  Smithing = {skType = skill.skillTypes.phys, train = 0.2},
  Alteration = {skType = skill.skillTypes.mag, train = 1},
  Conjuration = {skType = skill.skillTypes.mag, train = 0.1},
  Destruction = {skType = skill.skillTypes.mag, train = 0.7},
  Illusion = {skType = skill.skillTypes.mag, train = 0.1},
  Restoration = {skType = skill.skillTypes.mag, train = 1},
  Sex = {skType = skill.skillTypes.sex, train = 1},
  SackS = {skType = skill.skillTypes.sack, train = 0.7, activity = 0.5},
  SackM = {skType = skill.skillTypes.sack, train = 1, activity = 0.75},
  SackL = {skType = skill.skillTypes.sack, train = 1.5}
}

---Gets the training some skill contributes to the player.
---@param aSkill table
---@return number
local function _GetTraining(aSkill)
  return aSkill.train * aSkill.skType.train
end

---Gets how many hours of activity this skill is worth.
---@param aSkill table
---@return number
local function _GetActivity(aSkill)
  return (aSkill.activity or 1) * aSkill.skType.activity * 24
end

---Calculates values when the player trains.
---@param skillName string
---@return table
function skill.Train(skillName)
  local low = string.lower
  local sk = l.pipe(
    l.filter(function (_, k) return low(skillName) == low(k) end),
    l.extractValue
  )(skill.skills)
  local f0 = l.K(0)
  return {
    ---@type HumanHours
    --- Time added to last training time.
    activity = l.alt(_GetActivity, f0)(sk),

    ---@type number
    trainingDelta = l.alt(_GetTraining, f0)(sk),
  }
end

return skill
