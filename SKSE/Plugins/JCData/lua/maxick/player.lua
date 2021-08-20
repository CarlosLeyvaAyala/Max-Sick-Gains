local player = {}

local l = jrequire 'dmlib'
local db = jrequire 'maxick.database'
local sl = jrequire 'maxick.sliderCalc'
-- local serpent = require("__serpent")

-- Shortcuts to avoid too much words.

---Gets the current _Player stage_ as a table.
---@param playerStage number
---@return table
local function _Stage(playerStage) return db.playerStages[playerStage] end

---Gets the current _Fitness stage_ as a table.
---@param playerStage number
---@return table
local function _Fitstage(playerStage) return db.fitStages[_Stage(playerStage).fitStage] end

-- ;>========================================================
-- ;>===            APPEARANCE CALCULATIONS             ===<;
-- ;>========================================================

local function _SetHeadSize(actor)
  local st = _Stage(actor.stage)
  actor.headSize = l.linCurve({x=0, y=st.headLo}, {x=100, y=st.headHi})(actor.gains) / 100
  return actor
end

local function _StageChangeMsg(stage, msg)
  local display = db.playerStages[stage].displayName
  return l.IfThen(display ~= "", l.fmt(msg, display), "")
end

function player.LvlUpMessage(stage)
  return _StageChangeMsg(stage, "Your training has paid off. Now you look %s.")
end


-- ;>========================================================
-- ;>===               MUSCLE DEFINITION                ===<;
-- ;>========================================================

local function _GetMuscleDefBounds(mDefLo, mDefHi)
  if mDefLo > mDefHi then
    return true, mDefHi, mDefLo
  else
    return false, mDefLo, mDefHi
  end
end

local function _CalcMuscleDef(weight, mDefLo, mDefHi)
  local invert, mL, mH = _GetMuscleDefBounds(mDefLo, mDefHi)

  local cap = l.forceRange(mL, mH)
  local numBins = 100 / (mH - mL + 1)
  local r = math.floor(weight / numBins) + mL

  if invert then
    return mH - (cap(r) - mL)
  else
    return cap(r)
  end
end

local function _SetMuscleDef(actor)
  -- TODO: Ignore this if race is banned
  if false then
    actor.muscleDef = -1
    actor.muscleDefType = -1
  else
    local stage = _Stage(actor.stage)
    actor.muscleDef = _CalcMuscleDef(actor.gains, stage.muscleDefLo, stage.muscleDefHi)
    actor.muscleDefType = _Fitstage(actor.stage).muscleDefType
  end
  return actor
end

-- ;>========================================================
-- ;>===                   BODYSLIDE                    ===<;
-- ;>========================================================

local function _GetBlends(currentStage, gains)
  -- db.playerStages
  local b1, b2, blendStage, g2 = 0, 0, 0, 0
  local lBlendLim = db.playerStages[currentStage].blend
  local uBlendLim = 100 - db.playerStages[currentStage].blend

  if (lBlendLim >= gains) and (currentStage > 1) then
    -- This state is fresh. Blend with previous.
    blendStage = currentStage - 1
    b1 = l.linCurve({x=0, y=0.5}, {x=lBlendLim, y=1})(gains)
    g2 = 100
  elseif (uBlendLim <= gains) and (currentStage < #db.playerStages) then
    -- About to transition. Blend with next.
    blendStage = currentStage + 1
    b1 = l.linCurve({x=uBlendLim, y=1}, {x=100, y=0.5})(gains)
    g2 = 0
  else
    -- No need to blend
    b1 = 1
  end
  b2 = 1 - b1
  return currentStage, b1, gains, g2, blendStage, b2
end

local function _GetSliders(stageId, isFem, gains, sliders, blend)
  if (stageId < 1) or (blend == 0) then return {} end -- Nothing to calculate
  local stage = _Stage(stageId)
  local fitStage = db.fitStages[stage.fitStage]
  local bs = l.IfThen(isFem == 1, fitStage.femBs, fitStage.manBs)
  local weight = sl.WeightBasedAdjust(gains, stage.bsLo, stage.bsHi)

  return sl.CalcSliders(sliders, weight, bs, sl.BlendMorph(blend))
end

local function _GetActorSliders(actor, stageId, gains, blend)
  return _GetSliders(stageId, actor.isFem, gains, actor.bodySlide, blend)
end

local function _SetBodyslide(actor)
  local st1, bl1, g1, g2, st2, bl2 = _GetBlends(actor.stage, actor.gains)
  -- Current stage sliders
  local sl1 = _GetActorSliders(actor, st1, g1, bl1)
  -- Blend stage sliders
  local sl2 = _GetActorSliders(actor, st2, g2, bl2)
  -- Combine
  local blended = l.joinTables(sl1, sl2, function (v1, v2) return v1 + v2 end)
  l.assign(actor.bodySlide, blended)
  return actor
end

-- ;>========================================================
-- ;>===                     GAINS                      ===<;
-- ;>========================================================

---Calculates gains based on training and hours slept.
---@param actor Actor
---@param hoursSlept number
---@return Actor
local function _CalcGains(actor, hoursSlept)
  local sleepGains = l.forcePercent(hoursSlept / 10)
  sleepGains = math.min(sleepGains, actor.training)
  local maxGainsPerDay = 100 / _Stage(actor.stage).minDays
  actor.gains = actor.gains + sleepGains * maxGainsPerDay
  actor.training = actor.training - sleepGains
  return actor
end

--- Makes player advance levels if possible. Returns surplus Gains.
---@param stage integer
---@param gains number
---@return integer, number
local function _Progress(stage, gains)
  -- Can't go further
  if stage >= #db.playerStages then return #db.playerStages, 100 end
  -- Go to next level as usual
  return stage + 1, gains - 100
end

---Progress to next level if conditions are right.
---@param actor Actor
---@return Actor
local function _MakeProgress(actor)
  while actor.gains > 100 do
    local oldStage = actor.stage
    actor.stage, actor.gains = _Progress(oldStage, actor.gains)
    -- Adjust gains to new state ratio
    actor.gains = actor.gains * (_Stage(oldStage).minDays / _Stage(actor.stage).minDays)
  end
  return actor
end


-- ;>========================================================
-- ;>===                MAIN PROCESSING                 ===<;
-- ;>========================================================


---Attempts to make gains when sleeping.
---@param actor Actor
---@param hoursSlept number
---@return Actor
function player.OnSleep(actor, hoursSlept)
  return l.processActor(actor, {
    l.curryLast(_CalcGains, hoursSlept),
    _MakeProgress
  })
end

---Makes the calculations needed to change the player's appearance.
---@param actor Actor
---@return Actor
function player.ChangeAppearance(actor)
  return l.processActor(actor, {
    _SetBodyslide,
    _SetMuscleDef,
    _SetHeadSize
  })
end

return player
