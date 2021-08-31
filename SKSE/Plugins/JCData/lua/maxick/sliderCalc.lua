--{RELEASE}

local sliderCalc = {}

local l = jrequire 'dmlib'
local db = jrequire 'maxick.database'
local ml = jrequire 'maxick.lib'
-- local serpent = require("__serpent")


-- ;>========================================================
-- ;>===                   ONE LINERS                   ===<;
-- ;>========================================================

local _Clear = function() return 0 end
local _GetCalculated = function (_, v2) return v2 end

-- ;>========================================================
-- ;>===                    HELPERS                     ===<;
-- ;>========================================================

---Makes a linear interpolation with a `weight` that goes from 0 to `100`.
---@param weight number
---@param loBound number
---@param hiBound number
---@return number
function sliderCalc.WeightBasedAdjust(weight, loBound, hiBound)
  return l.linCurve({x=0, y=loBound}, {x=100, y=hiBound})(weight)
end

-- ;>========================================================
-- ;>===           SLIDER CALCULATION METHODS           ===<;
-- ;>========================================================

--- Calculates the value for a slider. This value is ready to be used by
--- `NiOverride.SetMorphValue()`
---@param gains integer 0 to 100. Skyrim weight related and `gains` for current player fitness stage.
---@param min integer 0 to 100. Skyrim weight related.
---@param max integer 0 to 100. Skyrim weight related.
---@return number sliderValue value
function sliderCalc.StdMorph(gains, min, max)
  return l.linCurve({x=0, y=min}, {x=100, y=max})(gains) / 100
end

---Returns a function that multiplies the result from `sliderCalc.StdMorph` by some multiplier.
---@param blend number
---@return function
function sliderCalc.BlendMorph(blend)
  return l.wrap(sliderCalc.StdMorph, function (f, ...) return f(...) * blend end)
end

-- ;>========================================================
-- ;>===               CALCULATE SLIDERS                ===<;
-- ;>========================================================

---Returns a table with all slider numbers using some `method`.
-- ---@param sliders table
-- ---@param weight integer
-- ---@param fitStageBs table
-- ---@param method function
-- function sliderCalc.CalcSliders(sliders, weight, fitStageBs, method)
--   local resetBs = l.map(sliders, _Clear)
--   local newVals = l.pipe(
--     l.reject(function (_, key) return fitStageBs[key] == nil end),
--     l.map(function (_, k) return method(weight, fitStageBs[k].min, fitStageBs[k].max) end)
--   )(sliders)

--   return l.joinTables(resetBs, newVals, _GetCalculated)
-- end

---Gets the slider values from database for a _Fitness stage_.
---@param fitStage integer
---@param isFem Sex
---@return table<string, table>
local function _GetSliders(fitStage, isFem)
  local st = db.fitStages[fitStage]
  return l.IfThen(l.SkyrimBool(isFem), st.femBs, st.manBs)
end

---Returns a table with all slider numbers using some `method`.
---@param weight number
---@param fitStage integer
---@param isFem Sex
---@param method fun(gains: number, min: number, max: number): number
---@return BodyslidePreset
function sliderCalc.GetBodyslide(weight, fitStage, isFem, method)
  ml.LogInfo(l.fmt("Applied weight: %.1f", weight))
  local fitStageBs = _GetSliders(fitStage, isFem)
  local sliders = l.keys(fitStageBs)
  return l.pipe(
    l.buildKeys(function (_, v) return v end),
    l.map(function (_, k) return method(weight, fitStageBs[k].min, fitStageBs[k].max) end)
  )(sliders)
end

-- ---Sets all slider numbers for an actor using some `method`.
-- ---@param actor table
-- ---@param weight integer
-- ---@param fitStageBs table
-- ---@param method function
-- function sliderCalc.SetBodySlide(actor, weight, fitStageBs, method)
--   l.assign(actor.bodySlide, sliderCalc.CalcSliders(actor.bodySlide, weight, fitStageBs, method))
-- end

return sliderCalc
