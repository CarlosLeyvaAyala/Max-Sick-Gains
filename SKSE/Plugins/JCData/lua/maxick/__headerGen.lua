-- Generates comment headers to separate code.

local __headerGen = {}
local n = 58
local s1 = ";>"..string.rep("=", n-2)
local hl = ";>==="
local hr = "===<;"
local s = " "

print("How will the header be named?")
local hc = io.read()

n = math.floor ((n - hl:len() - hr:len() - hc:len()) / 2)
local m = hc:len() % 2 == 0 and n or n + 1
hc = hl..s:rep(n)..hc:upper()..s:rep(m)..hr

local clipboard = require'clipboard'

clipboard.settext( s1.."\n"..hc.."\n"..s1)
print( clipboard.gettext() )
print("Was copied to clipboard!")

return __headerGen
