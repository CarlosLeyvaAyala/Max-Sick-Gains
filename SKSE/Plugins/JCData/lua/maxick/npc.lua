local npc = {}

local l = require 'dmlib'
local db = require 'database'
local serpent = require("serpent")

--;>-----------------------------------

local LogFactory  = function (actorData)
  return function (message) actorData.msg = actorData.msg .. message .. ". " end
end

--- Closure to log operations to `Actor.msg`.
--- Will be closed when `Actor` is known.
---@type function
local Log

--;>-----------------------------------

--- Calculates the value for a slider. This value is ready to be used by
--- `NiOverride.SetMorphValue()`
---@param gains integer 0 to 100. Skyrim weight related and `gains` for current player fitness stage.
---@param min integer 0 to 100. Skyrim weight related.
---@param max integer 0 to 100. Skyrim weight related.
---@return number sliderValue value
local function _BlendMorph(gains, min, max)
  return l.linCurve({x=0, y=min}, {x=100, y=max})(gains) / 100
end

--;>-----------------------------------

---Sets all slider numbers for an actor using some `method`.
---@param actor table
---@param weight integer
---@param bs table
---@param method function
local function SetBodySlide(actor, weight, bs, method)
  local resetBs = l.map(actor.bodySlide, function() return 0 end)
  local sliders = l.pipe(
    l.reject(function (_, key) return bs[key] == nil end),
    l.map(function (_, k) return method(weight, bs[k].min, bs[k].max) end)
  )(actor.bodySlide)

  l.assign(actor.bodySlide, resetBs)
  l.assign(actor.bodySlide, sliders)
end

--;>-----------------------------------
local function _SolveBodyslide(actor, fitStage)
  if actor.weight >= 0 then
    local bs
    if actor.isFem then bs = fitStage.femBs
    else bs = fitStage.manBs end
    SetBodySlide(actor, actor.weight, bs, _BlendMorph)
  else
    Log("Actor was banned from changing body shape")
  end
end

--;>-----------------------------------
local function _SolveMuscleDef(actor, fitStage)
  if actor.muscleDef >= 0 then
    actor.muscleDefType = fitStage.muscleDefType
  else
    actor.muscleDefType = -1
    Log("Won't change muscle definition")
  end
end

--;>-----------------------------------

--- Sets BodySlide sliders to a known `Actor` and determines which kind of muscle definition
--- will it use.
---@param actor table
---@return table
local function _ProcessKnownNPC(actor)
  if actor.shouldProcess == 0 then return actor end
  local fitStage = db.fitStages[actor.fitStage]

  _SolveBodyslide(actor, fitStage)
  _SolveMuscleDef(actor, fitStage)
  return actor
end

--;>-----------------------------------

local function _GetRacialMatches(actor)
  return l.filter(db.races,
    function (_, race)
      return string.find(string.lower(actor.raceEDID), race)
    end)
end

local function _Stop_CouldBeAnSpider(actor)
  actor.shouldProcess = 0
  Log(string.format("Race '%s' is not known by this mod. Ignore", actor.raceEDID))
end

local function _Stop_IsBanned(actor, display)
  local txt = "Can't change appearance. Actor race '%s' matched with banned race '%s'"
  Log(l.fmt(txt, actor.raceEDID, display))
  actor.shouldProcess = 0
end

local function _IsBanned(matches)
  return l.pipe(
    l.filter(function (val) return val.group == "Ban" end),
    l.extractValue
  )(matches)
end

local function _SetKnownRace(actor, matches)
  local val = l.pipe(l.take(1), l.extractValue)(matches)

  actor.racialGroup = val.group
  actor.raceDisplay = val.display
  actor.shouldProcess = 1
  return actor
end

local function _GetRace(actor)
  local matches = _GetRacialMatches(actor)
  -- print(serpent.block(matches))
  if l.tableLen(matches) < 1 then
    _Stop_CouldBeAnSpider(actor)
    return actor
  end
  local isBanned = _IsBanned(matches)
  if isBanned then
    _Stop_IsBanned(actor, isBanned.display)
    return actor
  end

  return _SetKnownRace(actor, matches)

end

--;>-----------------------------------

function npc.ProcessUnknownNPC(actor)
  Log = LogFactory(actor)
  _GetRace(actor)
  -- print(actor.msg)
  -- TODO: Get actor bodyslide
  if not actor.isFem then
    actor.shouldProcess = false
    Log("men not yet allowed")
    return actor
  end
  -- print(serpent.block(actor.bodySlide))
  if actor.shouldProcess then
    actor.fitStage = 1
    actor.muscleDef = 0
    npc.ProcessKnownNPC(actor)
    -- print(serpent.block(actor.bodySlide))
  end
  return actor
end

--;>-----------------------------------

---`Actor` was explicitly added by player. Process it.
---@param actor table
---@param values table
---@return table
local function _IsKnown(actor, values)
  actor.fitStage = values.fitStage
  if values.weight ~= 101 then actor.weight = values.weight end
  if values.muscleDef > 0 then actor.muscleDef = values.muscleDef end
  actor.isKnown = 1
  actor.shouldProcess = 1
  return actor
end

--;>-----------------------------------

local function _testSetStage(actor)
  actor.fitStage = 2
  actor.weight = 100
  actor.muscleDef = 6
  actor.isKnown = true
  -- actor.msg = "*** Explicitly added NPC ***"
  return actor
end

local function _SetStageData(actor)
  local fitStage = db.fitStages[actor.fitStage]
  return actor
end

--;>-----------------------------------

---Function for filtering a known NPC from`database.npcs`.
---@param actor table
---@return function
local function _FilterKNownNPC(actor)
  local fId = string.format("%.x", actor.formId)
  return l.filter(
    function(values, candidate)
      local idMatch = string.find(fId, candidate)
      local classMatch = values.class == string.lower(actor.class)
      local raceMatch = values.race == string.lower(actor.raceEDID)
      return idMatch and classMatch and raceMatch
    end
  )
end

--;>-----------------------------------

---Tries to find data for an explicitly set NPC.
---@param actor table
---@return table
local function _FindKnownNPC(actor)
  local npcMatch = l.pipe(
    _FilterKNownNPC(actor),
    l.take(1),
    l.extractValue
  )(db.npcs)

  if npcMatch then
    Log(l.fmt("*** Explicitly added NPC: '%s' ***", actor.name))
    return _IsKnown(actor, npcMatch)
  end

  return actor
end

--;>-----------------------------------

local function _GetToKnowNPC(actor)
  actor = _FindKnownNPC(actor)
  -- print(serpent.block(actor))
  if actor.isKnown == 0 then
    -- It's a generic NPC
    actor.shouldProcess = 0
    return _GetRace(actor)
  end
  return actor
end

--;>-----------------------------------

function npc.ProcessNPC(actor)
  -- if actor.shouldProcess ~= 1 then
  --   return actor
  -- end
  -- print(serpent.block(actor))
  local actorCopy = l.deepCopy(actor)
  Log = LogFactory(actorCopy)

  local processed = l.pipe(
    _GetToKnowNPC,
    -- get stage
    -- _testSetStage,
    _ProcessKnownNPC
  )(actorCopy)

  l.assign(actor, processed)
  print(serpent.block(actor))
  -- set stage data
  -- apply bodyslide
  return actor
end

return npc
