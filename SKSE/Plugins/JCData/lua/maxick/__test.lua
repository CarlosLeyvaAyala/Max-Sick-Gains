package.path = package.path..";F:/Skyrim SE/MO2/mods/DM-SkyrimSE-Library/SKSE/Plugins/JCData/lua/?/init.lua"

local l = require 'dmlib'

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
local p = l.pipe(
    l.map(rand),
    l.foreach(print),
    log("------------------"),
    l.skip(4),
    l.foreach(print),
    log("------------------"),
    l.reject(up5),
    l.foreach(print),
    log("------------------"),
    l.map(add2),
    l.foreach(print),
    log("------------------"),
    log("take 2"),
    l.take(2),
    l.foreach(print),
    log("------------------"),
    l.reduce(0, function (a, v) return a + v end),
    l.foreach(print),
    log("------------------"),
    l.any(up5),
    l.tap(print),
    l.foreach(print)
  )
p(data)

print("$$$$$$$$$$$$")

local function meh()
  local function meh2()

  end
end

local function meh2()
  return function ()
  end
end

local function meh3()
  return function (mehmehmeh)
    l.filter(mehmehmeh, function (mimimi) return mimimi == "meh" end)
  end
end

print(l.padZeros(4, 21))
print(l.hourSpan(0.5, 1))