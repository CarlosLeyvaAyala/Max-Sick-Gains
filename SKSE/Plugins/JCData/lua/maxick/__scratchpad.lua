package.path = package.path..";F:/Skyrim SE/MO2/mods/DM-SkyrimSE-Library/SKSE/Plugins/JCData/lua/?/init.lua"
package.path = package.path..";F:/Skyrim SE/MO2/mods/Max Sick Gains/SKSE/Plugins/JCData/lua/maxick/?.lua"
package.path = package.path..";F:/Skyrim SE/MO2/mods/Max-Sick-Gains-src/SKSE/Plugins/JCData/lua/maxick/?.lua"

local l = require 'dmlib'
local serpent = require("__serpent")
local db = require 'database'
--local sk = require 'skill'

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

-- print("$$$$$$$$$$$$")
-- local p = l.pipe(operations)
-- p(data)

-- print("$$$$$$$$$$$$")
-- pipe(operations)(data)

-- print("$$$$$$$$$$$$")

-- print(l.K(100)(nil))
-- print(l.K(l.I)(6)(7))
-- local first =l.K
-- local second = l.K(l.I)
-- print(first(1)(2))
-- print(second(1)(2))
-- print("$$$$$$$$$$$$")
-- local latin = function(selector) return selector("primus")("secundus") end
-- print(latin(first))
-- print(latin(second))
-- print(nil == nil)

print("$$$$$$$$$$$$")
local blindDate = l.once(function() return "Sure, what could go wrong?" end)
print(blindDate())
print(blindDate())
print(blindDate())

-- -- local ga = 100
-- local clipboard = require'clipboard'

-- print("$$$$$$$$$$$$$$$$$$$$$$$")
-- local table = "|-------|---------------|-----------------------|-----------------------|---------------|\n"
-- table = table .. "| stage\t| gains\t\t\t| Progress by stage %\t| Progress by days %\t| Average % \t|\n"
-- table = table .. "|-------|---------------|-----------------------|-----------------------|---------------|\n"
-- for st = 1, #db.playerStages, 1 do
--   for ga = 0, 100, 10 do
--     table = table .. string.format("| %d\t\t| %-3.0f\t\t\t| %.1f\t\t\t\t\t| %.1f\t\t\t\t\t| %.1f\t\t\t|\n", st, ga, _TotalJourney(st, ga))
--   end
-- end
-- table = table .. "|-------|---------------|-----------------------|-----------------------|---------------|\n"

-- clipboard.settext( table)
-- print( clipboard.gettext() )
-- print(table)
-- print("|---------------|---------------|-----------------------|-----------------------|---------------|")
-- print("| stage\t", "| gains\t", "| Progress by stage %", "| Progress by days %", "| Average % \t|")
-- print("|---------------|---------------|-----------------------|-----------------------|---------------|")
-- for st = 1, #db.playerStages, 1 do
--   for ga = 0, 100, 10 do
--     print(string.format("| %d\t\t| %.0f\t\t| %.1f\t\t\t| %.1f\t\t\t| %.1f\t\t|", st, ga, _TotalJourney(st, ga)))
--   end
-- end
-- print("|---------------|---------------|-----------------------|-----------------------|---------------|")

print("uu\"eiu\" ei")
i = 0xe000
for i = 0xdff0, 0xf010 do
  hex = string.format("%x", i)
  print("<code>", hex, " - </code>", "<span style=\"font-family: 'Material2';\">&#x".. hex ..";</span>", "<br>")
end
