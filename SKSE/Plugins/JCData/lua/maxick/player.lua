local player = {}

local l = jrequire 'dmlib'
local db = jrequire 'maxick.database'
local sl = jrequire 'maxick.sliderCalc'
local ml = jrequire 'maxick.lib'

-- local serpent = require("__serpent")
-- math.randomseed( os.time() )

--- Same named variables as [sampleNPC](npc.lua) have the same function. No need to document.
local samplePlayer = {
  bodySlide = ml.sampleSliders,
  isFem = 1,
  msg = "",
  muscleDefType = -1,
  muscleDef = -1,
  ---Used to know if muscle definition is banned for her race.
  raceEDID = "NordRaceAstrid",
  --- Current Player stage.
  stage = 1,
  --- Training that will get converted to `gains`. `[0..12]`
  training = 12,
  --- Player stage completition value. `If >= 100`, go up. `If < 0`, go down. `[0..100]`
  gains = math.random(100),
  --- Calculated head size.
  --- **`Out`** variable.
  headSize = 1.0,

  --;> Variables used to send mod events

  --- When changing player stage, tells how many stages went forward or back.
  evChangeStage = 0
}


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

---Calculates the head size for the player according to database.
---@param actor Actor
---@return Actor
local function _SetHeadSize(actor)
  local st = _Stage(actor.stage)
  --Head size is a percent value.
  actor.headSize = l.linCurve({x=0, y=st.headLo}, {x=100, y=st.headHi})(actor.gains) / 100
  ml.LogVerbose(l.fmt("Head size: %.1f%%", actor.headSize * 100))
  return actor
end

---Sets a display message only if a possible message exists in the database.
---@param stage number
---@param msg string
---@return string
local function _StageChangeMsg(stage, msg)
  local display = db.playerStages[stage].displayName
  return l.IfThen(display ~= "", l.fmt(msg, display), "")
end

---Returns the message displayed when going up in stages.
---@param stage integer Current stage.
---@return string
function player.LvlUpMessage(stage)
  return _StageChangeMsg(stage, "Your training has paid off. Now you look %s.")
end


-- ;>========================================================
-- ;>===               MUSCLE DEFINITION                ===<;
-- ;>========================================================

---Logs if the muscle definition won't be changed.
---@param actor Actor
local function _LogNotChangingMuscleDef(actor)
  if actor.muscleDef < 0 then
    ml.LogCrit("Won't change muscle definition")
  end
end

---Sets the invalid muscle definition.
---@param actor Actor
---@return Actor
local function _SetInvalidMuscleDef(actor)
  actor.muscleDef = -1
  actor.muscleDefType = -1
  ml.LogCrit("MCM: muscle definition changing banned")
  return actor
end

---Sets a valid muscle definition.
---@param actor Actor
---@return Actor
local function _SetValidMuscleDef(actor)
  local stage = _Stage(actor.stage)
  actor.muscleDef = l.round(sl.WeightBasedAdjust(actor.gains, stage.muscleDefLo, stage.muscleDefHi))
  actor.muscleDefType = _Fitstage(actor.stage).muscleDefType
  return actor
end

---Sets the muscle definition depending on MCM settings.
---@param actor Actor
---@return Actor
local function _SetMcmMuscleDef(actor)
  return l.alt2(db.mcm.playerMuscleDef, _SetValidMuscleDef, _SetInvalidMuscleDef)(actor)
end

---Sets muscle definition.
---@param actor Actor
---@return Actor
local function _SetMuscleDef(actor)
  return l.pipe(
    _SetMcmMuscleDef,
    ml.MuscleDefRaceBanned,
    l.tap(_LogNotChangingMuscleDef)
  )(actor)
end

-- ;>========================================================
-- ;>===                   BODYSLIDE                    ===<;
-- ;>========================================================

---Gets the values used for blending stages.
---@param currentStage integer
---@param gains number
---@return integer currentStage Current stage id.
---@return number currentBlend How much current stage contributes to blending.
---@return number currentStageGains On which `gains` current stage will be calculated.
---@return number blendStage Blending stage id.
---@return number blendStageBlend How much the blend stage contributes to blending.
---@return number blendStageGains  On which `gains` the blending stage will be calculated.
local function _GetBlends(currentStage, gains)
  local b1, b2, blendStage, g2 = 0, 0, 0, 0
  local lBlendLim = db.playerStages[currentStage].blend
  local uBlendLim = 100 - db.playerStages[currentStage].blend

  if (lBlendLim >= gains) and (currentStage > 1) then
    ml.LogVerbose("Current stage was blended with previous.")
    blendStage = currentStage - 1
    b1 = l.linCurve({x=0, y=0.5}, {x=lBlendLim, y=1})(gains)
    g2 = 100
  elseif (uBlendLim <= gains) and (currentStage < #db.playerStages) then
    ml.LogVerbose("Current stage was blended with next.")
    blendStage = currentStage + 1
    b1 = l.linCurve({x=uBlendLim, y=1}, {x=100, y=0.5})(gains)
    g2 = 0
  else
    ml.LogVerbose("No blending needed")
    b1 = 1
  end
  b2 = 1 - b1
  return currentStage, b1, gains, blendStage, b2, g2
end

---Calculates slider values.
---@param stageId integer Stage to getting sliders from.
---@param gains number Current gains to calculate slider values.
---@param blend number How much does `stageId` contributes to overall shape.
---@param isFem Sex Player sex.
---@param sliders table Table with the sliders the player has.
---@return table sliders
local function _GetSliders(stageId, isFem, gains, sliders, blend)
  if (stageId < 1) or (blend == 0) then return {} end -- Nothing to calculate
  local stage = _Stage(stageId)
  local fitStage = db.fitStages[stage.fitStage]
  local bs = l.IfThen(isFem == 1, fitStage.femBs, fitStage.manBs)
  local weight = sl.WeightBasedAdjust(gains, stage.bsLo, stage.bsHi)

  return sl.CalcSliders(sliders, weight, bs, sl.BlendMorph(blend))
end

---Calculates the slider values for an actor.
---@param actor Actor Player actor.
---@param stageId integer Stage to getting sliders from.
---@param gains number Current gains to calculate slider values.
---@param blend number How much does `stageId` contributes to overall shape.
---@return table sliders
local function _GetActorSliders(actor, stageId, gains, blend)
  return _GetSliders(stageId, actor.isFem, gains, actor.bodySlide, blend)
end

---Sets a blended Bodyslide for the player.
---@param actor Actor
---@return Actor
local function _SetBodyslide(actor)
  ml.LogCrit("Setting player appearance")
  local st1, bl1, g1, st2, bl2, g2 = _GetBlends(actor.stage, actor.gains)
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
---@return number gains
---@return number training
local function _CalcGains(actor, hoursSlept)
  local sleepGains = l.forcePercent(hoursSlept / 10)
  sleepGains = math.min(sleepGains, actor.training)
  local maxGainsPerDay = 100 / _Stage(actor.stage).minDays
  return actor.gains + sleepGains * maxGainsPerDay, actor.training - sleepGains
end

---Sets calulated gains.
---@param actor Actor
---@param hoursSlept number
---@return Actor
local function _SetGains(actor, hoursSlept)
  actor.gains, actor.training = _CalcGains(actor, hoursSlept)
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
    l.curryLast(_SetGains, hoursSlept),
    _MakeProgress
  })
end

---Makes the calculations needed to change the player's appearance.
---@param actor Actor
---@return Actor
function player.ChangeAppearance(actor)
  return l.processActor(actor, {
    ml.EnableSkyrimLogging,
    _SetBodyslide,
    _SetMuscleDef,
    _SetHeadSize,
    -- l.tap(serpent.piped)
  })
end

-- player.ChangeAppearance(samplePlayer)

return player
