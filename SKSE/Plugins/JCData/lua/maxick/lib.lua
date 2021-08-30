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
---@param variable string
---@return LoggingFunc
local LogFactory = function (variable)
  return function (message)
    if message and (message ~= "") then
      variable = variable .. message .. ". "
      print(variable, "log factory")
      return variable
    end
  end
end

local fullLog = ""

---Logs only messages that fit certain logging level.
---@param lvl integer
---@return LoggingFunc
local LogLevel = function (lvl)
  return function (message)
    if db.mcm.loggingLvl >= lvl and message and (message ~= "") then
      fullLog = fullLog .. message .. ". "
      return fullLog
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

---Returns the log with all messages appended so far.
---@return string
lib.GetLog = function () return l.trim(fullLog) end

---Makes possible to get messages out from here to Skyrim.
function lib.EnableSkyrimLogging()
  lib.LogCrit = LogLevel(gc.LoggingLvl.critical)
  lib.LogInfo = LogLevel(gc.LoggingLvl.info)
  lib.LogVerbose = LogLevel(gc.LoggingLvl.verbose)
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

---Returns an invalid muscle defintion.
---@return nil muscleDef
---@return nil muscleDefType
function lib.InvalidMuscleDef() return nil, nil end

---Returns wether the actor is banned from muscle definition applying due to her race.
---@param raceEDID string
---@return boolean
function lib.MuscleDefRaceBanned(raceEDID)
  local raceedid = string.lower(raceEDID)
  local found, race = lib.RaceInList(raceedid, db.muscleDefBanRace)
  if found then lib.LogCrit(l.fmt("Banned race '%s'", race)) end
  return found
end

return lib
