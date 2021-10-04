-- Test script for Lua code.
-- Open in ZeroBrane Studio and hit F6.

package.path = package.path..";F:/Skyrim SE/MO2/mods/DM-SkyrimSE-Library/SKSE/Plugins/JCData/lua/?/init.lua"
package.path = package.path..";F:/Skyrim SE/MO2/mods/Max Sick Gains/SKSE/Plugins/JCData/lua/maxick/?.lua"
package.path = package.path..";F:/Skyrim SE/MO2/mods/Max-Sick-Gains-src/SKSE/Plugins/JCData/lua/maxick/?.lua"

local l = require 'dmlib'
local db = require 'database'
local player = require 'player'
local serpent = require("__serpent")

local function Benchmark(f, ...)
  local startTime = os.clock()
  f(...)
  local elapsedTime = os.clock() - startTime
  return elapsedTime
  -- print("Elapsed time", elapsedTime)
end

local function test()
  -- require("__test_npc").Run()
  serpent.print(player.ChangeAppearance("Argonian", 0, 1, 50, 1))
  -- for i = 0, 100, 10 do
  --   local d = l.linCurve({x=0, y=1}, {x=100, y=6})(i)
  --   print(i, d, math.floor(d), l.round(d))
  -- end
end

test = l.wrap(test, Benchmark)

local t = {}

for _ = 1, 100, 1 do
  table.insert(t, test())
end
local sum = l.reduce(t, 0, function (a, v) return a + v end)
print("Average time per run", sum / l.tableLen(t))
