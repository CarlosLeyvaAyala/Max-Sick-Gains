--{RELEASE}

local race = {}

local l = jrequire 'dmlib'
local db = jrequire 'maxick.database'
local ml = jrequire 'maxick.lib'

---@alias RacialGroup number
---|'-1' Baned
---|'0' Humanoid
---|'1' Khajiit
---|'2' Argonian


-- ;>========================================================
-- ;>===                  RACE SOLVING                  ===<;
-- ;>========================================================

--#region

---Gets **all** the races from `database.races` an actor matches.
---This function can return if the race is banned and if it's humanoid/beast.
---@param raceEDID string
---@return table racialMatches A table with all races this actor matched with.
local function _GetRacialMatches(raceEDID)
  local raceedid = string.lower(raceEDID)
  return l.filter(db.races, function (_, aRace) return string.find(raceedid, aRace) end)
end

---Skyrim/PapyrusUtil didn't get all the actor info. Stop processing.
---@param actor Actor
local function _Stop_SkyrimIsBeingAnAsshole(actor)
  ml.LogCrit("WARNING: Skyrim didn't provide enough data to know who or what this actor is. Don't worry; you can fix this yourself with the Force Appearance hotkey")
  return nil
end

---Race is not recognized. Stop processing actor.
---@param raceEDID string
local function _Stop_CouldBeAnSpider(raceEDID)
  ml.LogVerbose(l.fmt("Race '%s' is not known by this mod", raceEDID))
  return nil
end

---Actor race is banned. Stop.
---@param raceEDID string
---@param display string The name of the race as written by the player in _Max Sick Gains.exe_
local function _Stop_IsBanned(raceEDID, display)
  local txt = "Can't change appearance; actor race '%s' matched with banned race '%s'"
  ml.LogCrit(l.fmt(txt, raceEDID, display))
  return nil
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

---The actor race was added by the player in _Max Sick Gains.exe_. If the NPC matches many races, only one will be taken. \
---At this point there shouldn't be many racial matches. _Max Sick Gains.exe_ should've refused to create such file.
---@param matches table All racial matches the NPC belongs to.
---@return RacialGroup racialGroup Formlist index of the racial group for the actor. Used to set muscle definition by texture.
local function _IsKnownRace(matches)
  local val = l.pipe(l.take(1), l.extractValue)(matches)
  ml.LogInfo(l.fmt("Actor race is '%s'", val.display))
  ml.LogVerbose(l.fmt("Racial group '%s'", val.group))
  return val.id
end

---Tries to find the race of the actor so it can be processed by other functions.
---@param raceEDID string
---@return nil|RacialGroup racialGroup Formlist index of the racial group for the actor. Used to set muscle definition by texture.
function race.RacialGroup(raceEDID)
  if raceEDID == "" then return _Stop_SkyrimIsBeingAnAsshole() end

  local matches = _GetRacialMatches(raceEDID)
  if l.isEmpty(matches) then return _Stop_CouldBeAnSpider(raceEDID) end

  local isBanned = _IsBanned(matches)
  if isBanned then return _Stop_IsBanned(raceEDID, isBanned.display) end

  return _IsKnownRace(matches)
end

--#endregion
return race
