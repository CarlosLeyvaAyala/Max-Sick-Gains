local npc = {}

local l = jrequire 'dmlib'
local ml = jrequire 'maxick.lib'
local db = jrequire 'maxick.database'
local sl = jrequire 'maxick.sliderCalc'
local serpent = require("__serpent")
--
---@alias LoggingFunc fun(message: string)

-- ;>========================================================
-- ;>===                    LOGGING                     ===<;
-- ;>========================================================

--#region

---Logs a message in the `actor`.
---@param actor Actor
---@return LoggingFunc
local LogFactory = function (actor)
  return function (message)
    if message then
      actor.msg = actor.msg .. message .. ". "
    end
  end
end

---Logs only messages that fit certain logging level.
---@param actor Actor
---@param lvl integer
---@return LoggingFunc
local LogLevel = function (actor, lvl)
  return function (message)
    if actor.loggingLvl >= lvl then
      LogFactory(actor)(message)
    end
  end
end

--- Critical message logging.
---@type LoggingFunc
local LogCrit

--- Misc info logging.
---@type LoggingFunc
local LogInfo

--- Really detailed info logging.
---@type LoggingFunc
local LogVerbose

---Makes possible to get messages out from here to Skyrim.
---@param actor Actor
---@return Actor
local function _EnableSkyrimLogging(actor)
  LogCrit = LogLevel(actor, ml.loggingLvl.Critical)
  LogInfo = LogLevel(actor, ml.loggingLvl.Info)
  LogVerbose = LogLevel(actor, ml.loggingLvl.Verbose)
  return actor
end

--#endregion

-- ;>========================================================
-- ;>===              PROCESS KNOWN ACTOR               ===<;
-- ;>========================================================

--#region

---Sets an actor bodyshape if it should be done.
---@param actor Actor
---@param fitStage table
local function _SolveBodyslide(actor, fitStage)
  if actor.weight >= 0 then
    local bs = l.IfThen(actor.isFem == 1, fitStage.femBs, fitStage.manBs)
    sl.SetBodySlide(actor, actor.weight, bs, sl.StdMorph)
  else
    LogInfo("Actor was banned from changing body shape")
  end
end

---Sets an actor muscle definition if it should be done.
---@param actor table
---@param fitStage table
local function _SolveMuscleDef(actor, fitStage)
  if actor.muscleDef >= 0 then
    actor.muscleDefType = fitStage.muscleDefType
  else
    actor.muscleDefType = -1
    LogInfo("Won't change muscle definition")
  end
end

--- Sets BodySlide sliders to a known `Actor` and determines which kind of muscle definition
--- will it use.
---@param actor Actor
---@return Actor
local function _ProcessKnownNPC(actor)
  if actor.shouldProcess == 0 then return actor end
  local fitStage = db.fitStages[actor.fitStage]

  _SolveBodyslide(actor, fitStage)
  _SolveMuscleDef(actor, fitStage)
  return actor
end

---`Actor` identity has bees solved. Process it.
---@param actor Actor
---@param values table
---@return Actor
local function _IsKnown(actor, values)
  actor.fitStage = values.fitStage
  if values.weight ~= 101 then actor.weight = values.weight end
  if values.muscleDef >= 0 then actor.muscleDef = values.muscleDef end
  actor.isKnown = 1
  actor.shouldProcess = 1
  return actor
end

--#endregion

-- ;>========================================================
-- ;>===                  RACE SOLVING                  ===<;
-- ;>========================================================

--#region

---Gets **all** the races from `database.races` an actor matches.
---This function can return if the race is banned and if it's humanoid/beast.
---@param actor Actor
---@return table
local function _GetRacialMatches(actor)
  return l.filter(db.races,
  function (_, race)
    return string.find(string.lower(actor.raceEDID), race)
  end)
end

---Race is not recognized. Stop processing actor.
---@param actor Actor
local function _Stop_CouldBeAnSpider(actor)
  actor.shouldProcess = 0
  LogCrit(l.fmt("Race '%s' is not known by this mod. Ignore", actor.raceEDID))
end

---Actor race is banned. Stop.
---@param actor Actor
---@param display string The name of the race as written by the player in _Max Sick Gains.exe_
local function _Stop_IsBanned(actor, display)
  local txt = "Can't change appearance. Actor race '%s' matched with banned race '%s'"
  LogCrit(l.fmt(txt, actor.raceEDID, display))
  actor.shouldProcess = 0
end

---Searches on all the matched races for a banned match and returns it.
---@param matches table
---@return table
local function _IsBanned(matches)
  return l.pipe(
    l.filter(function (val) return val.group == "Ban" end),
    l.extractValue
  )(matches)
end

---The actor race was added by the player in _Max Sick Gains.exe_. If the NPC matches many races, only one will be taken.
---@param actor Actor
---@param matches table All racial matches the NPC belongs to.
---@return Actor
local function _SetKnownRace(actor, matches)
  local val = l.pipe(l.take(1), l.extractValue)(matches)
  LogInfo(l.fmt("Actor race is '%s'", val.display))

  actor.racialGroup = val.group
  actor.raceDisplay = val.display
  actor.shouldProcess = 1
  return actor
end

---Skyrim/PapyrusUtil didn't get all the actor info. Stop processing.
---@param actor Actor
local function _Stop_SkyrimIsBeingAnAsshole(actor)
  actor.shouldProcess = 0
  LogCrit("WARNING: Skyrim didn't provide enough data to know who or what this actor is. Don't worry; this annoyance will eventually correct itself")
end

---Tries to find the race of the actor so it can be processed by other functions.
---@param actor Actor
---@return Actor
local function _GetRace(actor)
  if actor.raceEDID == "" then
    _Stop_SkyrimIsBeingAnAsshole(actor)
    return actor
  end

  local matches = _GetRacialMatches(actor)
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

--#endregion

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

local function _ArchetypesNames(possibleArchetypes)
  return l.pipe(
    l.map(function (id) return db.classArchetypes[id].iName end),
    l.map(l.encloseSingleQuote),
    l.reduce('', l.reduceCommaPretty)
  )(possibleArchetypes)
end

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

local function _GetSingleArchetype(usefulArchetypes)
  local len = l.tableLen(usefulArchetypes)
  if len == 1 then
    return usefulArchetypes[1]
  else
    local sel = math.random(len)
    LogCrit(l.fmt("Many viable archetypes; setting: '%s'",
      db.classArchetypes[usefulArchetypes[sel]].iName))
    return usefulArchetypes[sel]
  end
end

---Gets the archetype that will be applied to an NPC.
---@param actor table
---@param classMatch table
---@return number|nil
local function _GetBestArchetypeMatch(actor, classMatch)
  local possibleArchetypes = _AllAllowedArchetypes(actor, classMatch)
  if l.isEmpty(possibleArchetypes) then
    LogCrit(l.fmt("But no archetype was allowed for '%s' of that class", actor.raceEDID))
    return nil
  end
  -- Give preference to exclusive race archetypes
  local usefulArchetypes = _OnlyExclusiveArchetypes(actor, possibleArchetypes)
  LogVerbose(l.fmt("Matching archetype(s): %s", _ArchetypesNames(usefulArchetypes)))
  -- Return value
  return _GetSingleArchetype(usefulArchetypes)
end

local function _GetClassArchetype(actor)
  local class = string.lower(actor.class)
  -- ;WARNING: Modify this if function can't find the actor class
  local classMatch = l.filter(db.classes, function (_, k) return class == k end)
  if not l.isEmpty(classMatch) then
    LogCrit(l.fmt("Class found: '%s'", actor.class))
  else
    LogCrit(l.fmt("Couldn't find class: '%s'", actor.class))
    return nil
  end
  -- Find which archetype matches best this NPC
  return _GetBestArchetypeMatch(actor, classMatch)
end

local function _SetDefaultFitnessStage(actor)
  LogCrit("Setting default fitness stage")
  local values = {
    fitStage = 1,
    weight = actor.weight,
    muscleDef = 0,
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

--#region

---Filtering function that finds if an actor is a known NPC by searching them at `database.npcs`.
---@param actor Actor
---@return fun(actor: Actor): table
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
    LogCrit(l.fmt("*** Explicitly added NPC: '%s' ***", actor.name))
    -- TODO: Weight calculation by skills is possible to do right here
    -- TODO: Set muscle def and weight by MCM options
    return _IsKnown(actor, npcMatch)
  end

  return actor
end

---Gets the Bodyslide preset that will be applied to a generic NPC.
---This will set the _default Fitness stage_ if the NPC does not belong to any _archetype_.
---@param actor Actor
---@return Actor
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

---Gets the data needed to solve the identity of a generic NPC.
---@param actor Actor
---@return Actor
local function _FindUnknownNPCData(actor)
  return l.pipe(
    _GetRace,
    _GetGenericNPCBodyslide
  )(actor)
end

---Tries to find the identity of an actor.
---@param actor Actor
---@return Actor
local function _GetToKnowNPC(actor)
  actor = _FindKnownNPC(actor)
  if actor.isKnown == 0 then
    -- It's a generic NPC
    actor.shouldProcess = 0
    return _FindUnknownNPCData(actor)
  end
  return actor
end

--#endregion

-- ;>========================================================
-- ;>===                MAIN PROCESSING                 ===<;
-- ;>========================================================

---Makes all the calculations to change an NPC appearance.
---@param actor Actor
---@return Actor
function npc.ChangeAppearance(actor)
  return l.processActor(actor, {
    _EnableSkyrimLogging,
    _GetToKnowNPC,
    -- TODO: Ban fitness textures
    _ProcessKnownNPC,
    l.tap(serpent.piped)
  })
end

return npc
