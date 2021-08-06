package.path = package.path..";F:/Skyrim SE/MO2/mods/DM-SkyrimSE-Library/SKSE/Plugins/JCData/lua/?/init.lua"

local fitness = {
  {
    name = "Plain",
    blend = 0.3,
    days = 50,
    bsMin = 0.3,
    bsMax = 0.9,
    invert = true,
    bs= {
      ["Butt"] = {
        min = 10,
        max = 20
      },
      ["Boobs"] = {
        min = 0,
        max = 50
      }
    }
  },
  {
    name = "Hot",
    blend = 0.1,
    days = 160,
    invert = false,
    bsMin = 0.0,
    bsMax = 1.0,
    bs= {
      ["Butt"] = {
        min = 30,
        max = 60
      },
      ["Boobs"] = {
        min = 20,
        max = 80
      },
      ["7B Lower"] = {
        min = 10,
        max = 40
      }
    }
  },
  {
    name = "thief"
  },
  {
    name = "merchant"
  }
}

local l = require("dmlib")

--- Returns the value of a slider. 0 if it doesn't exist.
---
--- Example:
---
---     `val = _GetSliderVal(1, "7B Lower", "min")`
---@param level integer Fitness level as defined in `MaxSickGains.exe`. From obese to athlete.
---@param slider string Name of the slider as defined in the Bodyslide file.
---@param val string    Name of the property to get. Usually "min" or "max".
---@return number
local function _GetSliderVal(level, slider, val)
  -- ;FIXME: This will change when references to Bodyslides are used
    if fitness[level].bs[slider] ~= nil then return fitness[level].bs[slider][val]
    else return 0
  end
end

--- Returns the Bodyslide slider value corresponding to how much gains at some fitness level.
---
--- Example:
---
---`morph = GetSliderMorph(2, 0.5, "7B Lower")`
---@param level integer
---@param gains number
---@param slider string
---@param isPlayer boolean
---@return number
local function GetSliderMorph(level, gains, slider, isPlayer)
  isPlayer = isPlayer or false
  local min, max = 0.0, 0.0
  gains = l.forceRange(0, 1)(gains)
  min = _GetSliderVal(level, slider, "min")
  max = _GetSliderVal(level, slider, "max")

  -- Use boundaries if this slide will be applied to player
  if isPlayer then
    local oldMin = min
    min = l.linCurve({x=0.0, y=oldMin}, {x=1.0, y=max})(fitness[level].bsMin)
    max = l.linCurve({x=0.0, y=oldMin}, {x=1.0, y=max})(fitness[level].bsMax)
    if fitness[level].invert then min, max = max, min end
  end

  -- local r = l.linCurve({x=0.0, y=min}, {x=1.0, y=max})(gains)
  -- print(level, slider, min, max, r)
  return l.linCurve({x=0.0, y=min}, {x=1.0, y=max})(gains)
end

--- Gets the morph the player is expecting at her Fitness Level and Gains.
local function GetBlendedMorph(level, gains, slider)
  local r, b1, b2, s = 0, 0, 0, ""
  local lowerBlendLim = fitness[level].blend
  local upperBlendLim = 1.0 - fitness[level].blend

  if (lowerBlendLim >= gains) and (level > 1) then
    -- This state is fresh. Blend with previous.
    b1 = GetSliderMorph(level - 1, 1, slider, true)
    b2 = GetSliderMorph(level, gains, slider, true)
    b1 = b1 * l.linCurve({x=0, y=0.5}, {x=lowerBlendLim, y=0})(gains)
    b2 = b2 * l.linCurve({x=0, y=0.5}, {x=lowerBlendLim, y=1})(gains)
    r = b1 + b2
    s = "blended with previous"
  elseif (upperBlendLim <= gains) and (level < #fitness) then
    -- About to transition. Blend with next.
    b1 = GetSliderMorph(level, gains, slider, true)
    b2 = GetSliderMorph(level + 1, 0, slider, true)
    b1 = b1 * l.linCurve({x=upperBlendLim, y=1}, {x=1, y=0.5})(gains)
    b2 = b2 * l.linCurve({x=upperBlendLim, y=0}, {x=1, y=0.5})(gains)
    r = b1 + b2
    s = "blended with next"
  else
    -- No need to blend
    r = GetSliderMorph(level, gains, slider, true)
  end
  if s ~= "" then
    print(string.format("%d %.2f %-20s\tr= %.2f\t%s", level, gains, slider, r, s))
  end
  -- print(level, gains, slider, "r=", r, "b=",b1, b2, s)
end

--- Makes player advance levels if possible. Returns surplus Gains.
---@param level integer
---@param gains number
---@return integer
---@return number
local function _Progress(level, gains)
  -- Can't go further
  if level >= #fitness then return #fitness, 1.0 end
  -- Gains are too high. You qualify to next level, in fact. (shouldn't get this without cheating)
  if gains >= 2 then return _Progress(level + 1, gains - 1)
  -- Go to next level as usual
  else return level + 1, gains - 1
  end
end

local function _Regress(level, gains)
  -- Can't descend any further
  if level <= 1 then return 1, 0.0 end
  -- Gains are too low. Should never get to this point. Not even in jail.
  if gains <=-1 then return _Regress(level - 1, 1 + gains)
  --
  else return level - 1 , 1 + gains
  end
end

-- ####################################################################################

-- -- Simulate 10 hour sleep
-- local hoursSlept = 10
-- local gains = 0.0
-- local lvl = 1
-- local slider = "Boobs"
-- -- local i = 1
-- while gains < 1.0 do
--   -- Simulate sleeping
--   gains = gains + (1.0 / fitness[lvl].days) * (hoursSlept / 10)
--   GetBlendedMorph(lvl, gains, slider)
-- end

-- gains = 0
-- lvl = lvl + 1
-- -- while gains < 1.0 do
-- --   -- Simulate sleeping
-- --   gains = gains + (1.0 / fitness[lvl].days) * (hoursSlept / 10)
-- --   GetBlendedMorph(lvl, gains, slider)
-- -- end

-- local serpent = require('serpent')
-- -- print(serpent.block(fitness[3]))
-- -- print("lenght", l.tableLen(fitness))

-- print("length", #fitness)
-- print(_Regress(3, -1.01))
-- -- print(fitness[1].bs["Butt"].max)

print(string.format("%.x", 45))

-- local function filter(func, array)
--   local new_array = {}
--   for i,v in pairs(array) do
--     if func(v) then
--       new_array[i] = v
--     end
--   end
--   return new_array
-- end
-- local p = filter(function (x) return x > 5 end, {3,39,4,2,56,48,9,4,2,3,78})
-- print("")

local serpent = require("serpent")

local add2 = function(x) return x + 2 end
local sub1 = function(x) return x - 1 end
local pair = function(x) return (x % 2) == 0 end
local up5 = function(x) return x> 5 end
local rand = function () return math.random(10) end
local log = function (msg) return
  function (x)
    print(msg)
    return x
  end
end

local data=l.range(10)
-- l.foreach(l.reject(data, pair), print)
-- l.foreach(data, print)
local p = l.pipe(
    l.map(rand),
    l.foreach(print),
    log("------------------"),
    l.reject(up5),
    l.foreach(print),
    log("------------------"),
    l.map(add2),
    l.foreach(print),
    log("------------------"),
    l.reject(pair),
    l.foreach(print)
  )
p(data)
-- fr = l.foreach(print)
-- fr(data)
