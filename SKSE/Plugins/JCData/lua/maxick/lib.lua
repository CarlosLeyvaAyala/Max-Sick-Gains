--{RELEASE}

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

local fullLog = ""
local loggingLvl = 999    -- Log everything if failed to set logging value

---Sets the logging level so messages can be logged.\
---***This always needs to be called `OnGameReload`***.
---@param lvl integer
function lib.SetLoggingLvl(lvl) loggingLvl = lvl end

---Logs only messages that fit certain logging level.
---@param lvl integer
---@return LoggingFunc
local LogLevel = function (lvl)
  return function (message)
    if loggingLvl >= lvl and message and (message ~= "") then
      local tmp = "("..loggingLvl.." >= "..lvl..")"
      tmp = ""
      fullLog = fullLog .. tmp .. message .. ". "
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
  fullLog = ""
  lib.LogCrit = LogLevel(gc.LoggingLvl.critical)
  lib.LogInfo = LogLevel(gc.LoggingLvl.info)
  lib.LogVerbose = LogLevel(gc.LoggingLvl.verbose)
end

--#endregion

-- ;>========================================================
-- ;>===                ACTOR APPEARANCE                ===<;
-- ;>========================================================

---Returns the sex of the actor as string.
---@return "female"|"male"
function lib.SexAsStr(isFem)
  if isFem == 1 then
    return "female"
  else
    return "male"
  end
end

lib.SexAsStrPath = l.enum({"Man", "Fem"})
lib.RacialGroups = l.enum({"Hum","Kha","Arg"})
lib.MuscleDefTypes = l.enum({"Meh","Fit","Fat"})

---Returns the file path for the normal texture set that will be applied to an actor.
---@param muscleDef integer
---@param muscleDefType integer
---@param racialGroup integer
---@param isFem SkyrimBool
---@return string
function lib.GetNormalMapPath(muscleDef, muscleDefType, racialGroup, isFem)
  if not racialGroup then return "" end
  local path = "actors\\character\\Maxick\\%s\\%s%s_%.2d.dds"
  local val = l.fmt(path, lib.RacialGroups[racialGroup+1], lib.SexAsStrPath[isFem+1], lib.MuscleDefTypes[muscleDefType+1], muscleDef)
  lib.LogVerbose("'" .. val .. "'")
  return val
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
