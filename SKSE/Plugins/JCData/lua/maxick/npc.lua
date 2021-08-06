local npc = {}

local l = jrequire 'dmlib'
local db = jrequire 'maxick.database'
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

--- Sets all slider values to 0.
local function _ClearBodySlide(bs)
  for slider, _ in pairs(bs) do bs[slider] = 0 end
end

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
  -- Log = LogFactory(actor)
  local fitStage = db.fitStages[actor.fitStage]

  _SolveBodyslide(actor, fitStage)
  _SolveMuscleDef(actor, fitStage)
  return actor
end

--;>-----------------------------------

local function _GetRacialMatches(actor)
  local matches = {}
  for racialGroup, races in pairs(db.races) do
    for race, display in pairs(races) do
      if string.find(string.lower(actor.raceEDID), race) then
        matches[racialGroup] = {["race"] = race, ["display"] = display}
        -- print(racialGroup, race, display, string.lower(actor.raceEDID))
      end
    end
  end
  return matches
end

local function TableLength(t)
  local count = 0
  for _ in pairs(t) do count = count + 1 end
  return count
end

local function _Stop_CouldBeAnSpider(actor)
  actor.shouldProcess = false
  Log(string.format("Race '%s' is not known by this mod. Ignore", actor.raceEDID))
end

local function _Stop_IsBanned(actor, display)
  local txt = "Can't change appearance. Actor race '%s' matched with banned race '%s'"
  Log(string.format(txt, actor.raceEDID, display))
  actor.shouldProcess = false
end

local function _IsBanned(matches)
  for racialGroup, race in pairs(matches) do
    if racialGroup == 'Ban' then return true, race.display end
  end
  return false, ""
end

local function _SetKnownRace(actor, matches)
  for racialGroup, race in pairs(matches) do
    actor.race = race.race
    actor.racialGroup = racialGroup
    actor.raceDisplay = race.display
    actor.shouldProcess = true
    return actor
  end
end

local function _GetRace(actor)
  local matches = _GetRacialMatches(actor)
  if TableLength(matches) < 1 then
    _Stop_CouldBeAnSpider(actor)
    return actor
  end
  local isBanned, display = _IsBanned(matches)
  if isBanned then
    _Stop_IsBanned(actor, display)
    return actor
  end
  _SetKnownRace(actor, matches)
  return actor
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
  Log(string.format("*** Explicitly added NPC: '%s' ***", actor.name))
  actor.fitStage = values.fitStage
  if values.weight ~= 101 then actor.weight = values.weight end
  if values.muscleDef > 0 then actor.muscleDef = values.muscleDef end
  actor.isKnown = true
  actor.shouldProcess = true
  npc.ProcessKnownNPC(actor)
  return actor
end

--;>-----------------------------------

---Tries to find the actor in the npc database.
---@param actor table
---@return table
local function _Find(actor)
  if actor.name == "" then return actor end

  for id, values in pairs(db.npcs) do
    if string.find(id, string.lower(actor.name)) then
      local fId = string.format("%.x", actor.formId)
      if string.find(values.formId, fId) then return _IsKnown(actor, values) end
    end
  end
  return actor
end

--;>-----------------------------------

local function deepcopy(o, seen)
  seen = seen or {}
  if o == nil then return nil end
  if seen[o] then return seen[o] end

  local no
  if type(o) == 'table' then
    no = {}
    seen[o] = no

    for k, v in next, o, nil do
      no[deepcopy(k, seen)] = deepcopy(v, seen)
    end
    -- setmetatable(no, deepcopy(getmetatable(o), seen))
  else -- number, string, boolean, etc
    no = o
  end
  return no
end


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

function  npc.ProcessNPC(actor)
  Log = LogFactory(actor)
  if actor.shouldProcess ~= 1 then
    return actor
  end
  local p = l.pipe(
    -- get stage
    _testSetStage,
    _ProcessKnownNPC
  )
  -- set stage data
  -- apply bodyslide

  local processed = p(actor)
  return processed
end

return npc
