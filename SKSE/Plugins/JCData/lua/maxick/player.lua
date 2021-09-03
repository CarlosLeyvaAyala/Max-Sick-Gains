--{RELEASE}

local player = {}

local l = jrequire 'dmlib'
local db = jrequire 'maxick.database'
local sl = jrequire 'maxick.sliderCalc'
local ml = jrequire 'maxick.lib'

-- local serpent = require("__serpent")
-- math.randomseed( os.time() )

--- How much time could pass before entering catabolic state.
---@type HumanHours
player.inactivityTimeLimit = 48
--- How much `training` is lost a day due to decay.
player.trainingDecay = 0.2
--- How much `training` is lost a day when in _Catabolic State_.
player.trainingCatabolism = 0.5
--- How much `gains` are lost a day when in _Catabolic State_.
player.gainsCatabolism = 0.5
--- Max amount of training the player can have.
player.maxTraining = 12


--;> Shortcuts to avoid too much words.

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

--#region

---Calculates the head size for the player according to database.
---@param playerStage integer
---@param gains number
---@return number
function player.GetHeadSize(playerStage, gains)
  local st = _Stage(playerStage)
  --Head size is a percent value.
  local headSize = l.linCurve({x=0, y=st.headLo}, {x=100, y=st.headHi})(gains) / 100
  if ml.LogVerbose then
    ml.LogVerbose(l.fmt("Head size: %.1f%%", headSize * 100))
  end
  return headSize
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
function player.StageMessage(stage) return _StageChangeMsg(stage, "Now you look %s.") end


---Calculates percentage of the total journey only taking into account fitness stage progression.
---@param playerStage integer
---@param gains number
---@return number percent Number between [0, 1].
local function _TotalJourneyInStages(playerStage, gains)
  local f = l.linCurve({x=0, y=0}, {x=#db.playerStages, y=1})
  return l.forcePercent( f(playerStage - 1 + (gains / 100)) )
end

---Calculates percentage of the total journey only taking into account days of progression.
---@param playerStage integer
---@param gains number
---@return number percent Number between [0, 1].
local function _TotalJourneyInDays(playerStage, gains)
  local SumDays = function (a, v) return a + v.minDays end
  local totalDays = l.reduce(db.playerStages, 0, SumDays)
  local pastDays = l.pipe(
    l.takeA(playerStage - 1),
    l.reduce(0, SumDays)
  )(db.playerStages) + (db.playerStages[playerStage].minDays * (gains / 100))
  return l.forcePercent(pastDays / totalDays)
end

---Calculates percentage of the total journey so far.
---@param playerStage integer
---@param gains number
---@return number stagePercent Number between [0, 1].
---@return number daysPercent Number between [0, 1].
---@return number averagePercent Number between [0, 1].
local function _TotalJourney(playerStage, gains)
  local stagePercent = _TotalJourneyInStages(playerStage, gains)
  local daysPercent = _TotalJourneyInDays(playerStage, gains)
  return stagePercent, daysPercent, (stagePercent + daysPercent) / 2
end

--#endregion

-- ;>========================================================
-- ;>===               MUSCLE DEFINITION                ===<;
-- ;>========================================================

--#region

---Logs that the muscle definition won't be changed.
local function _LogNotChangingMuscleDef() ml.LogCrit("Won't change muscle definition") end

---Logs that muscle definition won't be changed.
---@return nil, nil
local function _MDefBanned() _LogNotChangingMuscleDef() return ml.InvalidMuscleDef() end

---Logs that muscle definition was disabled in the MCM.
---@return nil, nil
local function _MDefMcmBanned() ml.LogCrit("MCM: muscle definition changing banned") return _MDefBanned() end

---Sets a valid muscle definition.
---@param playerStage integer
---@param gains number
---@return integer muscleDef
---@return MuscleDefType muscleDefType
local function _ValidMuscleDef(playerStage, gains)
  local stage = _Stage(playerStage)
  local muscleDef = l.round(sl.WeightBasedAdjust(gains, stage.muscleDefLo, stage.muscleDefHi))
  local muscleDefType = _Fitstage(playerStage).muscleDefType
  return muscleDef, muscleDefType
end

---Returns the muscle definition the player should have.
---@param playerStage integer
---@param gains number
---@param applyMuscleDef SkyrimBool
---@param raceEDID string
---@return integer|nil muscleDef Muscle definition level.
---@return MuscleDefType|nil muscleDefType Muscle definition type.
local function _GetMuscleDef(playerStage, gains, applyMuscleDef, raceEDID)
  if not l.SkyrimBool(applyMuscleDef) then return _MDefMcmBanned()
  elseif ml.MuscleDefRaceBanned(raceEDID) then return _MDefBanned()
  else return _ValidMuscleDef(playerStage, gains)
  end
end

--#endregion

-- ;>========================================================
-- ;>===                   BODYSLIDE                    ===<;
-- ;>========================================================

--#region

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
  local b1, b2, blendStage, g2, bl = 0, 0, 0, 0, db.playerStages[currentStage].blend
  local lBlendLim, uBlendLim = bl, 100 - bl

  if (lBlendLim >= gains) and (currentStage > 1) then
    ml.LogVerbose("Current stage was blended with previous")
    blendStage, g2 = currentStage - 1, 100
    b1 = l.linCurve({x=0, y=0.5}, {x=lBlendLim, y=1})(gains)
  elseif (uBlendLim <= gains) and (currentStage < #db.playerStages) then
    ml.LogVerbose("Current stage was blended with next")
    blendStage, g2 = currentStage + 1, 0
    b1 = l.linCurve({x=uBlendLim, y=1}, {x=100, y=0.5})(gains)
  else
    ml.LogVerbose("No blending needed")
    b1 = 1
  end
  b2 = 1 - b1
  return currentStage, b1, gains, blendStage, b2, g2
end

---Calculates slider values.
---@param playerStage integer Stage to getting sliders from.
---@param gains number Current gains to calculate slider values.
---@param blend number How much does `stageId` contributes to overall shape.
---@param isFem Sex Player sex.
---@return BodyslidePreset sliders Calculated sliders.
local function _GetSliders(isFem, playerStage, gains, blend)
  if (playerStage < 1) or (blend == 0) then return {} end -- Nothing to calculate
  local stage = _Stage(playerStage)
  local weight = sl.WeightBasedAdjust(gains, stage.bsLo, stage.bsHi)
  return sl.GetBodyslide(weight, stage.fitStage, isFem, sl.BlendMorph(blend))
end

---Gets the blended Bodyslide for the player.
---@param isFem Sex
---@param playerStage integer
---@param gains number
---@return BodyslidePreset
local function _GetBodyslide(isFem, playerStage, gains)
  ml.LogCrit("Setting player appearance")
  local st1, bl1, g1, st2, bl2, g2 = _GetBlends(playerStage, gains)
  -- Current stage sliders
  local sl1 = _GetSliders(isFem, st1, g1, bl1)
  -- Blend stage sliders
  local sl2 = _GetSliders(isFem, st2, g2, bl2)
  -- Combine
  return l.joinTables(sl1, sl2, function (v1, v2) return v1 + v2 end)
end

--#endregion

-- ;>========================================================
-- ;>===                     GAINS                      ===<;
-- ;>========================================================

--#region

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

---Tells if this is the last stage.
---@type fun(stage: integer): boolean
local LastStage = function (stage) return stage >= #db.playerStages end

--- Makes player advance levels if possible. Returns surplus Gains.
---@param stage integer
---@param gains number
---@return integer, number
local function _Progress(stage, gains)
  -- Can't go further
  if LastStage(stage) then return #db.playerStages, 100 end
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
---@param stage integer
---@param gains number
---@param predicate fun(x: number): boolean
---@param f function
---@param AdjustGains function
---@return number newStage
---@return number adjustedGains
local function _ChangeStage(stage, gains, predicate, f, AdjustGains)
  while predicate(gains, stage) do
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
  if gains >= 100 then
    return _ChangeStage(stage, gains, function (x, s) return (x >= 100) and not LastStage(s) end, _Progress, _AdjustGainsOnProgress)
  elseif gains < 0 then
    return _ChangeStage(stage, gains, function (x) return x < 0 end, _Regress, _AdjustGainsOnRegress)
  end
  return stage, gains
end

---Avoids the `training` having invalid values.
---@param x number
---@return number
player.CapTraining = function (x) return l.forceRange(0, player.maxTraining)(x) end

--#endregion

-- ;>========================================================
-- ;>===                MAIN PROCESSING                 ===<;
-- ;>========================================================

---Makes the calculations needed to change the player's appearance.
---@param raceEDID string
---@param isFem Sex
---@param playerStage integer
---@param gains number
---@param applyMuscleDef SkyrimBool
function player.ChangeAppearance(raceEDID, isFem, playerStage, gains, applyMuscleDef)
  ml.EnableSkyrimLogging()
  local bs = _GetBodyslide(isFem, playerStage, gains)
  local md, mdt = _GetMuscleDef(playerStage, gains, applyMuscleDef, raceEDID)
  return {
    --- Irrelevant, but sent explicitly for clarity.
    weight = 100,
    --- Fully calculated appearance.
    bodySlide = bs,
    --- Muscle definition level.
    muscleDef = md or -1,
    muscleDefType = mdt or -1,
    headSize = player.GetHeadSize(playerStage, gains),
    --- Description of all operations that were done.
    msg = ml.GetLog(),
    --- Player should be always processed by `Maxick_ActorAppearance.ChangeAppearance()`.
    shouldProcess = 1,
  }
end

-- print(serpent.block(player.ChangeAppearance("NordRaceAstri", 1, 3, 100, 1)))

---Attempts to make gains when sleeping.
---@param hoursSlept number
---@param training number
---@param gains number
---@param stage integer
---@return table
function player.OnSleep(hoursSlept, training, gains, stage)
  local gainsDelta, newTraining, newGains = _MakeGains(hoursSlept, training, stage, gains)
  local newStage, adjustedGains = _AdjustStage(stage, newGains)
  local Cap = function (g) return l.IfThen(LastStage(newStage), l.forceMax(100)(g), g) end
  local cappedGains = Cap(adjustedGains)
  local stagePercent, daysPercent, averagePercent = _TotalJourney(newStage, cappedGains)
  return {
    gainsDelta = gainsDelta,
    newTraining = newTraining,
    newGains = cappedGains,
    newStage = newStage,
    stageDelta = newStage - stage,

    -- Percents of the whole journey made so far
    stagePercent = stagePercent,
    daysPercent = daysPercent,
    averagePercent = averagePercent,
  }
end

---Calculates last training time given a change in it.
---Used to calculate inactivity.
---@param now SkyrimHours Captain Obvious to the rescue!
---@param lastTrained SkyrimHours Captain Obvious to the rescue!
---@param delta SkyrimHours Maybe doesn't have sense to make negative values. Let's what people comes out with.
---@return SkyrimHours newLastTrained Adjusted value for activity.
function player.HadActivity(now, lastTrained, delta)
  local Cap = function (x) return l.forceRange(now - l.ToGameHours(player.inactivityTimeLimit), now)(x) end
  -- Make sure inactivity is within acceptable values before updating
  local capped = Cap(lastTrained)
  -- Update value
  return Cap(capped + delta)
end

-- ;>========================================================
-- ;>===                    POLLING                     ===<;
-- ;>========================================================

--#region

---Calculates losses on `gains` when in _Catabolic State_.
---@param stage integer
---@return number
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
  local Catabolism = function (x) return l.alt2(l.SkyrimBool(inCatabolism), PollAdjust, l.K(0))(x) end

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

--#endregion

-- print(serpent.block(player.Polling(1, 0, 10, 0, 2, 1)))
-- print(serpent.block(player.ChangeAppearance(samplePlayer)))
-- print(serpent.block(player.OnSleep(10, 12, 0, 1)))
-- print(serpent.block(player.CatabolicWaste(3, 6)))

return player
