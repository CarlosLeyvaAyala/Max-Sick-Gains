package.path = package.path..";F:/Skyrim SE/MO2/mods/DM-SkyrimSE-Library/SKSE/Plugins/JCData/lua/?/init.lua"

local l = require 'dmlib'
local serpent = require("serpent")

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

local add2 = function(x) return x + 2 end
local sub1 = function(x) return x - 1 end
local pair = function(x) return (x % 2) == 0 end
local up5 = function(x) return x > 5 end
local rand = function () return math.random(10) end
local log = function (msg) return function (x) print(msg) return x end end

local pipe = function(fnList)
  return function(arg)
    return l.reduce(fnList, arg, function(a, f) return f(a) end)
  end
end
pipe = l.forceTableInput(pipe)

local data = l.map(l.range(10), rand)
local operations = {
  l.foreach(l.unary(print)),
  log("------------------"),
  log("skip 4"),
  l.skip(4),
  l.foreach(l.unary(print)),
  log("------------------"),
  log("reject up5"),
  l.reject(up5),
  l.foreach(l.unary(print)),
  log("------------------"),
  log("map add2"),
  l.map(add2),
  l.foreach(l.unary(print)),
  log("------------------"),
  log("take 2"),
  l.take(2),
  l.foreach(l.unary(print)),
  log("------------------"),
  log("reduce sum"),
  l.reduce(0, function (a, v) return a + v end),
  l.foreach(l.unary(print)),
  log("------------------"),
  l.any(up5),
  l.tap(print),
  l.foreach(print)
}

-- local function add(x, y) return x + y end
-- local pipedAdd = l.makePipeable(add, 2)
-- print(pipe(pipedAdd(20), pipedAdd(50))(30))
-- print(pipedAdd(2,3))


-- print("$$$$$$$$$$$$")
local p = l.pipe(operations)
p(data)

print("$$$$$$$$$$$$")
pipe(operations)(data)

print("$$$$$$$$$$$$")

print(l.K(100)(nil))
print(l.K(l.I)(6)(7))
local first =l.K
local second = l.K(l.I)
print(first(1)(2))
print(second(1)(2))
print("$$$$$$$$$$$$")
-- local latin = function(selector) return selector("primus")("secundus") end
-- print(latin(first))
-- print(latin(second))
-- print(nil == nil)

print(l.maybe(add2)(3))
print(l.maybe(add2)(nil))
print("$$$$$$$$$$$$")
local blindDate = l.once(function() return "Sure, what could go wrong?" end)
print(blindDate())
print(blindDate())
print(blindDate())

print(string.find("--{RELEASE} local npc = {}", "{RELEASE}"))