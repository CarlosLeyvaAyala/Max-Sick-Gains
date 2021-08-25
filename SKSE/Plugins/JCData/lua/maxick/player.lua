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
---@param hoursSlept number
---@param training number
---@param stage integer
---@return number gainsDelta This value will get out to Skyrim as a delta.
---@return number training This value will be set "as is" in Skyrim; bypassing widget flashes.
local function _CalcGains(hoursSlept, training, stage)
  local sleepGains = l.forcePercent(hoursSlept / 10)
  sleepGains = math.min(sleepGains, training)
  local maxGainsPerDay = 100 / _Stage(stage).minDays
  return sleepGains * maxGainsPerDay, training - sleepGains
end

---Makes gains when sleeping.
---@param hoursSlept number
---@param training number
---@param stage integer
---@param gains number
---@return number gainsDelta
---@return number newTraining
---@return number newGains
local function _MakeGains(hoursSlept, training, stage, gains)
  local gainsDelta, newTraining = _CalcGains(hoursSlept, training, stage)
  return gainsDelta, newTraining, gains + gainsDelta
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

--- Makes player regress levels if possible. Returns surplus Gains.
---@param stage integer
---@param gains number
---@return integer, number
local function _Regress(stage, gains)
  -- Can't descend any further
  if stage <= 1 then return 1, 0 end
  -- Gains will be taken care of by the adjusting function
  return stage - 1, gains
end

--- Adjusts gains to new stage ratio.
---@param gains number
---@param oldStage integer
---@param currentStage integer
---@return number
local function _AdjustGainsOnProgress(gains, oldStage, currentStage)
  return gains * (_Stage(oldStage).minDays / _Stage(currentStage).minDays)
end

--- Adjusts gains to new stage ratio.
---@param gains number
---@param oldStage integer
---@param currentStage integer
---@return number
local function _AdjustGainsOnRegress(gains, oldStage, currentStage)
  if gains >= 0 then return gains end
  local r = _Stage(oldStage).minDays / _Stage(currentStage).minDays
  return 100 + (gains * r)
end

---Changes stage while some predicate is true. Returns adjusted gains for the new stage.
local function _ChangeStage(stage, gains, predicate, f, AdjustGains)
  while predicate(gains) do
    local oldStage = stage
    stage, gains = f(oldStage, gains)
    gains = AdjustGains(gains, oldStage, stage)
  end
  return stage, gains
end

---Returns a new stage and adjusted gains depending on current `gains`.
---Can gain or lose levels.
---@param stage integer
---@param gains number
---@return integer newStage
---@return number newGains
---@return integer stageDelta
local function _AdjustStage(stage, gains)
  local oldStage
  if gains >= 100 then
    return _ChangeStage(stage, gains, function (x) return x > 100 end, _Progress, _AdjustGainsOnProgress)
  elseif gains < 0 then
    return _ChangeStage(stage, gains, function (x) return x < 0 end, _Regress, _AdjustGainsOnRegress)
  end
  return stage, gains
end

-- ;>========================================================
-- ;>===                MAIN PROCESSING                 ===<;
-- ;>========================================================

---Makes the calculations needed to change the player's appearance.
---@param actor Actor
---@return Actor
function player.ChangeAppearance(actor)
  return l.processActor(actor, {
    ml.EnableSkyrimLogging,
    _SetBodyslide,
    _SetMuscleDef,
    _SetHeadSize,
  })
end

---Attempts to make gains when sleeping.
---@param hoursSlept number
---@param training number
---@param gains number
---@param stage integer
---@return table
function player.OnSleep(hoursSlept, training, gains, stage)
  local gainsDelta, newTraining, newGains = _MakeGains(hoursSlept, training, stage, gains)
  local newStage, adjustedGains = _AdjustStage(stage, newGains)
  return {
    gainsDelta = gainsDelta,
    newTraining = newTraining,
    newGains = adjustedGains,
    newStage = newStage,
    stageDelta = newStage - stage
  }
end

--- How much time could pass before entering catabolic state.
---@type HumanHours
player.inactivityTimeLimit = 48

---Calculates last training time given a change in it.
---Used to calculate inactivity.
---@param now SkyrimHours Captain Obvious to the rescue!
---@param lastTrained SkyrimHours Captain Obvious to the rescue!
---@param delta SkyrimHours Maybe doesn't have sense to make negative values. Let's what people comes out with.
---@return SkyrimHours newLastTrained Adjusted value for activity.
function player.HadActivity(now, lastTrained, delta)
  local Cap = function (x) return l.forceRange(l.ToGameHours(player.inactivityTimeLimit), now)(x) end
  -- Make sure inactivity is within acceptable values before updating
  local capped = Cap(lastTrained)
  -- Update value
  return Cap(capped + delta)
end

print(player.HadActivity(10, 9, 2))

-- ;>========================================================
-- ;>===                    POLLING                     ===<;
-- ;>========================================================

player.trainingDecay = 0.3
player.trainingCatabolism = 0.5
player.gainsCatabolism = 0.5

local function _GainsCatabolism(stage)
  return 1 / db.playerStages[stage].minDays * player.gainsCatabolism
end

---Makes the calculations that should be done each step.
---@param now SkyrimHours Time for this poll.
---@param lastPoll SkyrimHours Last time the poll was run.
---@param training number Player training.
---@param gains number Player gains.
---@param stage integer Player stage id.
---@param inCatabolism SkyrimBool Is player losing because too inactive?
function player.Polling(now, lastPoll, training, gains, stage, inCatabolism)
  local PollAdjust = function (x) return (now - lastPoll) * x end
  local Catabolism = function (x) return l.IfThen(l.SkyrimBool(inCatabolism), PollAdjust(x), 0) end

  local trainingDecay = PollAdjust(player.trainingDecay)
  -- Catabolism calculations
  local trainingCatabolism = Catabolism(player.trainingCatabolism)
  local gainsCatabolism = Catabolism(_GainsCatabolism(stage))
  local newStage, adjustedGains = _AdjustStage(stage, gains - gainsCatabolism)
  return {
    newGains = adjustedGains,
    newTraining = l.forcePositve(training - trainingCatabolism - trainingDecay),
    newStage = newStage,
    stageDelta = newStage - stage,
  }
end

-- print(serpent.block(player.Polling(1, 0, 10, 0, 2, 1)))
-- print(serpent.block(player.ChangeAppearance(samplePlayer)))
-- print(serpent.block(player.OnSleep(10, 0.2, -6, 3)))
-- print(serpent.block(player.CatabolicWaste(3, 6)))

return player
