--- Shared functions that only make sense for this mod
local lib = {}

local l = jrequire 'dmlib'
local db = jrequire 'maxick.database'
local gc = jrequire 'maxick.genConst'

--- Dummy sliders used for testing algorithms.
lib.sampleSliders = {
  BreastFlatness = 1000,
  BreastHeight = 1000,
  ButtClassic = 1000,
  Waist = 1000,
  BellyFrontDownFat_v2 = 1000,
  DummySlider = 1.0,
  ManyOtherSliders = 0
}

-- ;>========================================================
-- ;>===                    LOGGING                     ===<;
-- ;>========================================================

--#region

---Logs a message in the `actor`.
---@param actor Actor
---@return LoggingFunc
local LogFactory = function (actor)
  return function (message)
    if message and (message ~= "") then
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
    if db.mcm.loggingLvl >= lvl then
      LogFactory(actor)(message)
    end
  end
end

--- Critical message logging.
---@type LoggingFunc
lib.LogCrit = nil

--- Misc info logging.
---@type LoggingFunc
lib.LogInfo = nil

--- Really detailed info logging.
---@type LoggingFunc
lib.LogVerbose = nil

---Makes possible to get messages out from here to Skyrim.
---@param actor Actor
---@return Actor
function lib.EnableSkyrimLogging(actor)
  lib.LogCrit = LogLevel(actor, gc.LoggingLvl.critical)
  lib.LogInfo = LogLevel(actor, gc.LoggingLvl.info)
  lib.LogVerbose = LogLevel(actor, gc.LoggingLvl.verbose)
  return actor
end

--#endregion

-- ;>========================================================
-- ;>===                ACTOR APPEARANCE                ===<;
-- ;>========================================================

---Returns the sex of the actor as string.
---@param actor Actor
---@return "female"|"male"
function lib.SexAsStr(actor)
  if actor.isFem == 1 then
    return "female"
  else
    return "male"
  end
end

---Finds if some race is in a race list.
---@param race string
---@param raceList table
---@return boolean
function lib.RaceInList(race, raceList)
  return l.any(raceList, function (v) return string.find(race, v) end)
end

---Returns wether the actor is banned from muscle definition applying due to her race.
---@param actor Actor
---@return Actor
function lib.MuscleDefRaceBanned(actor)
  local found, race = lib.RaceInList(string.lower(actor.raceEDID), db.muscleDefBanRace)
  if found then
    lib.LogCrit(l.fmt("Banned race '%s'", race))
    actor.muscleDef = -1
  end
  return actor
end

return lib
