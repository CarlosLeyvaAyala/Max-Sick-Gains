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
  -- print(serpent.block(bs))
  _ClearBodySlide(actor.bodySlide)

  for slider, values in pairs(bs) do
    actor.bodySlide[slider] = method(weight, values.min, values.max)
  end
  -- print(serpent.block(actor.bodySlide))
end

--;>-----------------------------------
-- local function ProcessSingleActor(id, actor)
--   -- Delete JContainers extra data to be able to find actor
--   actor.msg = "Processing " .. id
--   local uId = string.sub(id, string.len("__formData|") + 1)
--   if db.NPCs[uId] then
--     actor.msg = actor.msg .. " Known actor"
--     actor.shouldProcess = true
--     local bs = actor.isFem and db.NPCs[uId].fitStage.femBs or db.NPCs[uId].fitStage.manBs
--     _SetBodySlide(actor, db.NPCs[uId].weight, bs, _BlendMorph)
--   else
--     --Unknown actor.
--     actor.msg = actor.msg .. " unknown actor"
--   end
-- end

--;>-----------------------------------
-- function npc.getData(aPapyrusData)
--   ProcessSingleActor(aPapyrusData.id.___id, aPapyrusData)
--   -- for uId, _ in pairs(aPapyrusData.id) do
--   -- end
--   -- print(serpent.block(aPapyrusData))
--   return aPapyrusData
-- end

--;>-----------------------------------
local function _SolveBodyslide(actor, fitStage)
  if actor.weight >= 0 then
    local bs = actor.isFem and fitStage.femBs or fitStage.manBs
    SetBodySlide(actor, actor.weight, bs, _BlendMorph)
  else Log("Actor was banned from changing body shape")
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
function npc.ProcessKnownNPC(actor)
  Log = LogFactory(actor)
  local fitStage = db.fitStages[actor.fitStage]

  _SolveBodyslide(actor, fitStage)
  _SolveMuscleDef(actor, fitStage)
  return actor
end

return npc
