local npc = {}

local l = jrequire 'dmlib'
local db = jrequire 'maxick.database'
-- local serpent = require("serpent")

--;>-----------------------------------
local function _ClearBodySlide(bs)
  for slider, _ in pairs(bs) do
    bs[slider] = 0
  end
end

--;>-----------------------------------
--- Calculates the value for a slider. This value is ready to be used by
--- `NiOverride.SetMorphValue`
---@param gains integer [0..100]
---@param min integer [0..100]
---@param max integer [0..100]
---@return number
local function _BlendMorph(gains, min, max)
  return l.linCurve({x=0, y=min}, {x=100, y=max})(gains) / 100
end

--;>-----------------------------------
local function _SetBodySlide(actor, weight, bs, method)
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
function npc.ProcessKnownNPC(actor)
  actor.msg = "Known actor " .. actor.fitStage
  local bs = actor.isFem and db.fitStages[actor.fitStage].femBs or db.fitStages[actor.fitStage].manBs
  _SetBodySlide(actor, actor.weight, bs, _BlendMorph)

  -- print(serpent.block(actor))
  return actor
end

return npc
