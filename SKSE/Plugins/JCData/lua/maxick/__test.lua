-- Test script for Lua code.
-- Open in ZeroBrane Studio and hit F6.

package.path = package.path..";F:/Skyrim SE/MO2/mods/DM-SkyrimSE-Library/SKSE/Plugins/JCData/lua/?/init.lua"
package.path = package.path..";F:/Skyrim SE/MO2/mods/Max Sick Gains/SKSE/Plugins/JCData/lua/maxick/?.lua"
package.path = package.path..";F:/Skyrim SE/MO2/mods/Max-Sick-Gains-src/SKSE/Plugins/JCData/lua/maxick/?.lua"

local l = require 'dmlib'
local db = require 'database'
local player = require 'player'
local serpent = require("__serpent")

require("__test_npc").Run()
serpent.print(player.ChangeAppearance("Argonian", 0, 1, 50, 1))
