local npc = {}

local l = jrequire 'dmlib'
local db = jrequire 'maxick.database'
local sl = jrequire 'maxick.sliderCalc'
-- local serpent = require("serpent")

--;>-----------------------------------

local LogFactory  = function (actorData)
  return function (message) actorData.msg = actorData.msg .. message .. ". " end
end

--- Closure to log operations to `Actor.msg`.
--- Will be closed when `Actor` is known.
---@type function
local Log

--;>-----------------------------------
local function _SolveBodyslide(actor, fitStage)
  if actor.weight >= 0 then
    local bs = l.IfThen(actor.isFem == 1, fitStage.femBs, fitStage.manBs)
    sl.SetBodySlide(actor, actor.weight, bs, sl.StdMorph)
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

-- ;>========================================================
-- ;>===                  RACE SOLVING                  ===<;
-- ;>========================================================

local function _GetRacialMatches(actor)
  return l.filter(db.races,
  function (_, race)
    return string.find(string.lower(actor.raceEDID), race)
  end)
end

--;>-----------------------------------

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

local function _Stop_SkyrimIsBeingAnAsshole(actor)
  actor.shouldProcess = 0
  Log("WARNING: Skyrim didn't provide enough data to know who or what this actor is. Don't worry; this annoyance will eventually correct itself")
end

--;>-----------------------------------

local function _GetRace(actor)
  if actor.raceEDID == "" then
    _Stop_SkyrimIsBeingAnAsshole(actor)
    return actor
  end
  local matches = _GetRacialMatches(actor)
  -- if l.tableLen(matches) < 1 then
  if l.isEmpty(matches) then
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
    -- TODO: Weight calculation by skills is possible to do right here
    -- TODO: Set muscle def and weight by MCM options
    return _IsKnown(actor, npcMatch)
  end

  return actor
end

-- ;>========================================================
-- ;>===                 CLASS SOLVING                  ===<;
-- ;>========================================================

-- TODO: Seems to be a function that should be in a library

---Finds if some race is in a race list.
---@param race string
---@param raceList table
---@return boolean
local function _RaceInList(race, raceList)
  return l.any(raceList, function (v) return string.find(race, v) end)
end

local function _ClassArchetypeAllowed(race, exclusiveRaceList)
  local allRacesAllowed = l.isEmpty(exclusiveRaceList)
  if allRacesAllowed then return true end     -- Optimization

  local raceMatch = _RaceInList(race, exclusiveRaceList)
  return raceMatch
end

local function _ClassArchetypeExclusive(race, exclusiveRaceList)
  return _RaceInList(race, exclusiveRaceList)
end

--;>-----------------------------------

local function _ArchetypesNames(possibleArchetypes)
  return l.pipe(
    l.map(function (id) return db.classArchetypes[id].iName end),
    l.map(l.encloseSingleQuote),
    l.reduce('', l.reduceCommaPretty)
  )(possibleArchetypes)
end

--;>-----------------------------------

---Returns a list of all allowed archetypes for a class-race.
---@param actor table
---@param classMatch table
---@return table
local function _AllAllowedArchetypes(actor, classMatch)
  return l.filter(
    l.flatten(classMatch),
    function (archId)
      local racesList = db.classArchetypes[archId].raceExclusive
      return _ClassArchetypeAllowed(string.lower(actor.raceEDID), racesList)
    end
  )
end

local function _OnlyExclusiveArchetypes(actor, possibleArchetypes)
  local exclusiveOnly = l.filter(
    possibleArchetypes,
    function (archId)
      local racesList = db.classArchetypes[archId].raceExclusive
      return _ClassArchetypeExclusive(string.lower(actor.raceEDID), racesList)
    end
  )
  local ex = l.dropNils(exclusiveOnly)
  return l.IfThen(not l.isEmpty(ex), ex, possibleArchetypes)
end

--;>-----------------------------------
local function _GetSingleArchetype(usefulArchetypes)
  local len = l.tableLen(usefulArchetypes)
  if len == 1 then
    return usefulArchetypes[1]
  else
    local sel = math.random(len)
    Log(l.fmt("Many viable archetypes; setting: '%s'",
      db.classArchetypes[usefulArchetypes[sel]].iName))
    return usefulArchetypes[sel]
  end
end

--;>-----------------------------------

---Gets the archetype that will be applied to an NPC.
---@param actor table
---@param classMatch table
---@return number|nil
local function _GetBestArchetypeMatch(actor, classMatch)
  local possibleArchetypes = _AllAllowedArchetypes(actor, classMatch)
  if l.isEmpty(possibleArchetypes) then
    Log(l.fmt("But no archetype was allowed for '%s' of that class", actor.raceEDID))
    return nil
  end
  -- Give preference to exclusive race archetypes
  local usefulArchetypes = _OnlyExclusiveArchetypes(actor, possibleArchetypes)
  Log(l.fmt("Matching archetype(s): %s", _ArchetypesNames(usefulArchetypes)))
  -- Return value
  return _GetSingleArchetype(usefulArchetypes)
end

--;>-----------------------------------

local function _GetClassArchetype(actor)
  local class = string.lower(actor.class)
  -- ;WARNING: Modify this if function can't find the actor class
  local classMatch = l.filter(db.classes, function (_, k) return class == k end)
  if not l.isEmpty(classMatch) then
    Log(l.fmt("Class found: '%s'", actor.class))
  else
    Log(l.fmt("Couldn't find class: '%s'", actor.class))
    return nil
  end
  -- Find which archetype matches best this NPC
  return _GetBestArchetypeMatch(actor, classMatch)
end

--;>-----------------------------------
local function _SetDefaultFitnessStage(actor)
  Log("Setting default fitness stage")
  local values = {
    fitStage = 1,
    weight = actor.weight,
    muscleDef = -1
  }
  actor = _IsKnown(actor, values)
  return actor
end

local function _SetClassArchetypeData(actor, archId)
  local arch = db.classArchetypes[archId]
  -- TODO: Set muscle def and weight by MCM options
  local values = {
    fitStage = arch.fitStage,
    weight = sl.WeightBasedAdjust(actor.weight, arch.bsLo, arch.bsHi),
    muscleDef = l.round(sl.WeightBasedAdjust(actor.weight, arch.muscleDefLo, arch.muscleDefHi))
  }
  actor = _IsKnown(actor, values)
  return actor
end

-- ;>========================================================
-- ;>===              NPC IDENTITY SOLVING              ===<;
-- ;>========================================================

local function _GetGenericNPCBodyslide(actor)
  if actor.shouldProcess == 0 then return actor end
  local arch = _GetClassArchetype(actor)
  if arch then
    -- Apply archetype data
    actor = _SetClassArchetypeData(actor, arch)
  else
    -- Apply default body
    actor = _SetDefaultFitnessStage(actor)
  end
  return actor
end

--;>-----------------------------------

local function _FindUnknownNPCData(actor)
  return l.pipe(
    _GetRace,
    _GetGenericNPCBodyslide
  )(actor)
end

--;>-----------------------------------

local function _GetToKnowNPC(actor)
  actor = _FindKnownNPC(actor)
  if actor.isKnown == 0 then
    -- It's a generic NPC
    actor.shouldProcess = 0
    return _FindUnknownNPCData(actor)
  end
  return actor
end

-- ;>========================================================
-- ;>===                MAIN PROCESSING                 ===<;
-- ;>========================================================

function npc.ProcessNPC(actor)
  local actorCopy = l.deepCopy(actor)
  Log = LogFactory(actorCopy)

  local processed = l.pipe(
    _GetToKnowNPC,
    _ProcessKnownNPC
    -- TODO: Ban fitness textures
  )(actorCopy)

  l.assign(actor, processed)
  return actor
end

return npc
