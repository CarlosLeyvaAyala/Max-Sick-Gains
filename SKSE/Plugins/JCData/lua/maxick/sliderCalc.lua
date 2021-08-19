local sliderCalc = {}

local l = jrequire 'dmlib'


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

--;>-----------------------------------

---Returns a function that multiplies the result from `sliderCalc.StdMorph` by some multiplier.
---@param blend number
---@return function
function sliderCalc.BlendMorph(blend)
  return l.wrap(sliderCalc.StdMorph, function (func, ...) return func(...) * blend end)
end

-- ;>========================================================
-- ;>===               CALCULATE SLIDERS                ===<;
-- ;>========================================================

---Returns a table with all slider numbers using some `method`.
---@param sliders table
---@param weight integer
---@param fitStageBs table
---@param method function
function sliderCalc.CalcSliders(sliders, weight, fitStageBs, method)
  local resetBs = l.map(sliders, _Clear)
  local newVals = l.pipe(
    l.reject(function (_, key) return fitStageBs[key] == nil end),
    l.map(function (_, k) return method(weight, fitStageBs[k].min, fitStageBs[k].max) end)
  )(sliders)

  return l.joinTables(resetBs, newVals, _GetCalculated)
end

  --;>-----------------------------------

---Sets all slider numbers for an actor using some `method`.
---@param actor table
---@param weight integer
---@param fitStageBs table
---@param method function
function sliderCalc.SetBodySlide(actor, weight, fitStageBs, method)
  l.assign(actor.bodySlide, sliderCalc.CalcSliders(actor.bodySlide, weight, fitStageBs, method))
end

return sliderCalc