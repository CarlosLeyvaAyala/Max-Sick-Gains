--{RELEASE}

local npc = {}

local l = jrequire 'dmlib'
-- local gc = jrequire 'maxick.genConst'
local db = jrequire 'maxick.database'
local sl = jrequire 'maxick.sliderCalc'
local ml = jrequire 'maxick.lib'
-- local serpent = require("__serpent")

math.randomseed( os.time() )


-- ;>========================================================
-- ;>===              PROCESS KNOWN ACTOR               ===<;
-- ;>========================================================

--#region

---Sets an actor bodyshape if it should be done.
---@param fitStage integer
---@param weight number
---@param isFem Sex
---@return BodyslidePreset
local function _SolveBodyslide(fitStage, weight, isFem)
  if weight and (weight >= 0) then
    return sl.GetBodyslide(weight, fitStage, isFem, sl.StdMorph)
  else
    ml.LogInfo("Won't change body shape") return {}
  end
end

---Logs a message saying it won't change muscle definition and sends out invalid values.
---@return nil
---@return nil
local function _WontChangeMuscleDef()
  ml.LogInfo("Won't change muscle definition")
  return nil, nil
end

---Sets an actor muscle definition if it should be done.
---@param fitStage integer
---@param muscleDef MuscleDef
---@param raceEDID string
---@return nil|MuscleDef muscleDef
---@return nil|MuscleDefType muscleDefType
local function _SolveMuscleDef(fitStage, muscleDef, raceEDID)
  if not muscleDef or muscleDef < 0 then return _WontChangeMuscleDef() end
  if ml.MuscleDefRaceBanned(raceEDID) then return _WontChangeMuscleDef() end
  return muscleDef, db.fitStages[fitStage].muscleDefType
end

--- Sets BodySlide sliders to a known `Actor` and determines which kind of muscle definition
--- will it use.
---@param fitStage integer
---@param weight number
---@param muscleDef MuscleDef
---@param shouldProcess SkyrimBool
---@param raceEDID string
---@param isFem Sex
---@return BodyslidePreset
---@return MuscleDef|nil
---@return MuscleDefType|nil
---@return SkyrimBool
local function _ProcessKnownNPC(fitStage, weight, muscleDef, shouldProcess, raceEDID, isFem)
  if not weight and not muscleDef then ml.LogCrit("Nothing to process") return {}, nil, nil, 0 end
  if not l.SkyrimBool(shouldProcess) then return {}, nil, nil, 0 end

  local bs = _SolveBodyslide(fitStage, weight, isFem)
  local md, mdt = _SolveMuscleDef(fitStage, muscleDef, raceEDID)
  return bs, md, mdt, 1
end

---`Actor` identity has bees solved. Process it.
---@param values table
---@param npcWeight number
---@return integer fitStage
---@return number weight
---@return MuscleDef muscleDef
---@return SkyrimBool shouldProcess
local function _IsKnown(values, npcWeight)
  local fitStage = values.fitStage
  local weight = l.IfThen(values.weight and values.weight == 101, npcWeight, values.weight)
  local muscleDef = l.IfThen(values.muscleDef and (values.muscleDef >= 0), values.muscleDef, nil)
  local shouldProcess = 1
  return fitStage, weight, muscleDef, shouldProcess
end

-- ;>========================================================
-- ;>===                   MCM CONFIG                   ===<;
-- ;>========================================================

local function _McmBsBan(canChange, values)
  if not l.SkyrimBool(canChange) then
    ml.LogCrit("MCM: Bodyslide applying disabled")
    values.weight = nil
  end
end

local function _McmMuscleBan(canChange, values)
  if not l.SkyrimBool(canChange) then
    ml.LogCrit("MCM: Muscle definition changing disabled")
    values.muscleDef = nil
  end
end

---Applies Bodyslide and muscle definition bans if it was configured like that in the MCM.
---@param canChangeBs SkyrimBool
---@param canChangeMuscle SkyrimBool
---@param values table
---@return table
local function _McmBan(canChangeBs, canChangeMuscle, values)
  _McmBsBan(canChangeBs, values)
  _McmMuscleBan(canChangeMuscle, values)
  return values
end

local function _McmGenericBsBySex(isFem, mcm)
  return l.IfThen(isFem == 1, mcm.gNpcFemBs, mcm.gNpcManBs)
end

local function _McmGenericMusDefBySex(isFem, mcm)
  return l.IfThen(isFem == 1, mcm.gNpcFemMuscleDef, mcm.gNpcManMuscleDef)
end

local function _McmGenericBanned(isFem, mcm)
  local bsBan = not l.SkyrimBool(_McmGenericBsBySex(isFem, mcm))
  local musDefBan = not l.SkyrimBool(_McmGenericMusDefBySex(isFem, mcm))
  return bsBan and musDefBan
end

local function _DisableGeneric(isFem)
  ml.LogCrit(l.fmt("Generic %s NPC processing was disabled in MCM", ml.SexAsStr(isFem)))
  return nil
end

--#endregion


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
  return l.filter(db.races, function (_, race) return string.find(raceedid, race) end)
end

---Race is not recognized. Stop processing actor.
---@param raceEDID string
local function _Stop_CouldBeAnSpider(raceEDID)
  ml.LogCrit(l.fmt("Race '%s' is not known by this mod", raceEDID))
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

---The actor race was added by the player in _Max Sick Gains.exe_. If the NPC matches many races, only one will be taken.
---@param matches table All racial matches the NPC belongs to.
---@return SkyrimBool shouldProcess
local function _IsKnownRace(matches)
  local val = l.pipe(l.take(1), l.extractValue)(matches)
  ml.LogInfo(l.fmt("Actor race is '%s'", val.display))
  return 1
end

---Skyrim/PapyrusUtil didn't get all the actor info. Stop processing.
---@param actor Actor
local function _Stop_SkyrimIsBeingAnAsshole(actor)
  ml.LogCrit("WARNING: Skyrim didn't provide enough data to know who or what this actor is. Don't worry; you can fix this yourself with the Force Appearance hotkey")
end

---Tries to find the race of the actor so it can be processed by other functions.
local function _RaceIsValid(raceEDID)
  if raceEDID == "" then return _Stop_SkyrimIsBeingAnAsshole() end

  local matches = _GetRacialMatches(raceEDID)
  if l.isEmpty(matches) then return _Stop_CouldBeAnSpider(raceEDID) end

  local isBanned = _IsBanned(matches)
  if isBanned then return _Stop_IsBanned(raceEDID, isBanned.display) end

  return _IsKnownRace(matches)
end

--#endregion

-- ;>========================================================
-- ;>===                 CLASS SOLVING                  ===<;
-- ;>========================================================


local function _ClassArchetypeAllowed(race, exclusiveRaceList)
  local allRacesAllowed = l.isEmpty(exclusiveRaceList)
  if allRacesAllowed then return true end     -- Optimization

  local raceMatch = ml.RaceInList(race, exclusiveRaceList)
  return raceMatch
end

local function _ClassArchetypeExclusive(race, exclusiveRaceList)
  return ml.RaceInList(race, exclusiveRaceList)
end

local function _ArchetypesNames(possibleArchetypes)
  return l.pipe(
    l.map(function (id) return db.classArchetypes[id].iName end),
    l.map(l.encloseSingleQuote),
    l.reduce('', l.reduceCommaPretty)
  )(possibleArchetypes)
end

---Returns a list of all allowed archetypes for a class-race.
---@param raceEDID string
---@param classMatch table
---@return table possibleArchetypes All archetypes this NPC belongs to.
local function _AllAllowedArchetypes(raceEDID, classMatch)
  local raceedid = string.lower(raceEDID)
  return l.dropNils(l.filter(
    l.flatten(classMatch),
    function (archId)
      local racesList = db.classArchetypes[archId].raceExclusive
      return (_ClassArchetypeAllowed(raceedid, racesList))
    end
  ))
end

---Returns a list with the archetypes where the NPC has race exclusivity. \
---If no match was found, returns `possibleArchetypes`.
---@param raceEDID string
---@param possibleArchetypes table
---@return table
local function _OnlyExclusiveArchetypes(raceEDID, possibleArchetypes)
  local raceedid = string.lower(raceEDID)
  local exclusiveOnly = l.filter(
    possibleArchetypes,
    function (archId)
      local racesList = db.classArchetypes[archId].raceExclusive
      return _ClassArchetypeExclusive(raceedid, racesList)
    end
  )
  local ex = l.dropNils(exclusiveOnly)
  return l.IfThen(not l.isEmpty(ex), ex, possibleArchetypes)
end

---Retuns the archetype that best matched the NPC. If many were found, randomly returns any of them.
---@param usefulArchetypes table
---@return number archetypeId Id of the archetype that will be applied.
local function _GetSingleArchetype(usefulArchetypes)
  local len = l.tableLen(usefulArchetypes)
  if len == 1 then
    return usefulArchetypes[1]
  else
    local sel = math.random(len)
    ml.LogCrit(l.fmt("Many viable archetypes; setting: '%s'",
      db.classArchetypes[usefulArchetypes[sel]].iName))
    return usefulArchetypes[sel]
  end
end

---Gets the archetype that will be applied to an NPC.
---@param raceEDID string
---@param classMatch table
---@return nil|number archetypeId Id of the archetype that will be applied.
local function _GetBestArchetypeMatch(raceEDID, classMatch)
  local possibleArchetypes = _AllAllowedArchetypes(raceEDID, classMatch)
  if l.isEmpty(possibleArchetypes) then
    ml.LogCrit(l.fmt("But no archetype was allowed for '%s' of that class", raceEDID))
    return nil
  end
  -- Give preference to exclusive race archetypes
  local usefulArchetypes = _OnlyExclusiveArchetypes(raceEDID, possibleArchetypes)
  ml.LogVerbose(l.fmt("Matching archetype(s): %s", _ArchetypesNames(usefulArchetypes)))
  -- Return value
  return _GetSingleArchetype(usefulArchetypes)
end

---Gets a class archetype for the NPC.
---@param Class string
---@param raceEDID string
---@return nil|number archetypeId Id of the archetype that will be applied.
local function _GetClassArchetype(Class, raceEDID)
  local class = string.lower(Class)
  local classMatch = l.filter(db.classes, function (_, k) return string.find(class, k) end)
  if not l.isEmpty(classMatch) then
    ml.LogCrit(l.fmt("Class found: '%s'", Class))
  else
    ml.LogCrit(l.fmt("Couldn't find class: '%s'", Class))
    return nil
  end
  -- Find which archetype matches best this NPC
  return _GetBestArchetypeMatch(raceEDID, classMatch)
end

---Sets the default fitness stage. Used when no archetype was found for the actor.
---@return integer fitStage
---@return number weight
---@return MuscleDef muscleDef
---@return SkyrimBool shouldProcess
local function _SetDefaultFitnessStage(isFem, mcm, weight)
  ml.LogCrit("Setting default fitness stage")
  local values = {
    fitStage = 1,
    weight = weight,
    muscleDef = 0,
    muscleDefType = db.fitStages[1].muscleDefType
  }
  values = _McmBan(_McmGenericBsBySex(isFem, mcm), _McmGenericMusDefBySex(isFem, mcm), values)
  return _IsKnown(values, weight)
end

---Returns all the data needed for applying appearance to an NPC.
---@param archId number Id of the archetype to apply to NPC.
---@param isFem Sex Sex.
---@param mcm table MCM options for appearance applying.
---@param weight number Duh.
---@return integer fitStage
---@return number weight
---@return MuscleDef muscleDef
---@return SkyrimBool shouldProcess
local function _SetClassArchetypeData(archId, isFem, mcm, weight)
  local arch = db.classArchetypes[archId]
  local values = {
    fitStage = arch.fitStage,
    weight = sl.WeightBasedAdjust(weight, arch.bsLo, arch.bsHi),
    muscleDef = l.round(sl.WeightBasedAdjust(weight, arch.muscleDefLo, arch.muscleDefHi))
  }
  values = _McmBan(_McmGenericBsBySex(isFem, mcm), _McmGenericMusDefBySex(isFem, mcm), values)
  return _IsKnown(values, weight)
end

-- ;>========================================================
-- ;>===              NPC IDENTITY SOLVING              ===<;
-- ;>========================================================

--#region Known NPC

---Filtering function that finds if an actor is a known NPC by searching them at `database.npcs`.
---@return fun(actor: Actor): table
local function _FilterKNownNPC(formId, Name, raceEDID, isFem, Class)
  local fId = string.format("%.x", formId)
  local class, name, raceedid = string.lower(Class), string.lower(Name), string.lower(raceEDID)
  -- ;FIXME: Make a takeFirst function
  return l.filter(
    function(values, candidate)
      local idMatch = string.find(fId, candidate)
      local classMatch = values.class == class
      local raceMatch = values.race == raceedid
      local sexMatch = values.isFemale == l.SkyrimBool(isFem)
      -- ;WARNING: Delete name matching if NPC can no longer be found
      local nameMatch = values.fullName == name
      return idMatch and classMatch and raceMatch and nameMatch and sexMatch
    end
  )
end

---Tries to find data for an explicitly set NPC.
---@param formId number
---@param name string
---@param raceEDID string
---@param isFem Sex
---@param class string
---@param weight number
---@param mcm table
---@return nil|integer fitStage
---@return number weight
---@return MuscleDef muscleDef
---@return SkyrimBool shouldProcess
local function _FindKnownNPC(formId, name, raceEDID, isFem, class, weight, mcm)
  local npcMatch = l.pipe(
    _FilterKNownNPC(formId, name, raceEDID, isFem, class),
    l.take(1),
    l.extractValue
  )(db.npcs)

  if npcMatch then
    ml.LogCrit(l.fmt("*** Explicitly added NPC: '%s' ***", name))
    -- TODO: Weight calculation by skills is possible to do right here
    return _IsKnown(_McmBan(mcm.kNpcBs, mcm.kNpcMuscleDef, npcMatch), weight)
  end

  return nil
end

--#endregion

--#region Generic NPC

---Gets the Bodyslide preset that will be applied to a generic NPC.
---This will set the _default Fitness stage_ if the NPC does not belong to any _archetype_.
---@return integer fitStage
---@return number weight
---@return MuscleDef muscleDef
---@return SkyrimBool shouldProcess
local function _GetGenericNPCData(class, raceEDID, isFem, mcm, weight)
  local arch = _GetClassArchetype(class, raceEDID)
  if arch then
    return _SetClassArchetypeData(arch, isFem, mcm, weight)
  else
    return _SetDefaultFitnessStage(isFem, mcm, weight)
  end
end

---Gets the data needed to solve the identity of a generic NPC.
---@return integer fitStage
---@return number weight
---@return MuscleDef muscleDef
---@return SkyrimBool shouldProcess
local function _FindUnknownNPCData(raceEDID, isFem, class, weight, mcm)
  if _McmGenericBanned(isFem, mcm) then return _DisableGeneric(isFem) end
  if _RaceIsValid(raceEDID) then return _GetGenericNPCData(class, raceEDID, isFem, mcm, weight) end
  return nil
end

---Tries to find the identity of an actor.
---@return integer fitStage
---@return number weight
---@return MuscleDef muscleDef
---@return SkyrimBool shouldProcess
local function _GetToKnowNPC(formId, name, raceEDID, isFem, class, weight, mcm)
  local fitStage, newWeight, muscleDef, shouldProcess =
    _FindKnownNPC(formId, name, raceEDID, isFem, class, weight, mcm)
  if not shouldProcess then
    -- It's a generic NPC
    return _FindUnknownNPCData(raceEDID, isFem, class, weight, mcm)
  end
  return fitStage, newWeight, muscleDef, shouldProcess
end

--#endregion

-- ;>========================================================
-- ;>===                MAIN PROCESSING                 ===<;
-- ;>========================================================

---Makes all the calculations to change an NPC appearance.
function npc.ChangeAppearance(data)
  ml.EnableSkyrimLogging()
  local fitStage, weight, muscleDef, shouldProcess =
  _GetToKnowNPC(data.formId, data.name, data.raceEDID, data.isFem, data.class, data.weight, data.mcm)
  local bs, md, mdt, process = _ProcessKnownNPC(fitStage, weight, muscleDef, shouldProcess, data.raceEDID, data.isFem)
  return {
    --- Used to know if will get Bodyslide applied.
    weight = weight or -1,
    --- Fully calculated appearance.
    bodySlide = bs,
    --- Muscle definition level.
    muscleDef = md or -1,
    muscleDefType = mdt or -1,
    --- Description of all operations that were done.
    msg = ml.GetLog(),
    --- Should it be processed by `Maxick_ActorAppearance.ChangeAppearance()`?
    shouldProcess = process or 0,
  }
end

-- print(serpent.block(npc.ChangeAppearance({
--   --- MCM options from Papyrus
--   mcm = {
--     kNpcBs = 1,
--     kNpcMuscleDef = 1,
--     gNpcFemBs = 1,
--     gNpcFemMuscleDef = 1,
--     gNpcManBs = 1,
--     gNpcManMuscleDef = 1,
--   },
--   --- Actor name. Used to try to find it in the known npcs database.
--   name = "Laydia",
--   --- Used to try to find it in the known npcs database.
--   formId = 0xa2c8e,
--   --- Used to calculate body slider values. Range: `[0..100]`.
--   --- Either user assigned in Known NPCs or gotten from the game.
--   weight = math.random(100),
--   --- Class name as gotten from PapyrusUtil.
--   class = "Warrior",
--   raceEDID = "NordRace",
--   isFem = 0,
-- })
-- ))

return npc
