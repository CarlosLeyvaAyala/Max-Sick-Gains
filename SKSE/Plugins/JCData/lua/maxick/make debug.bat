@echo off
Title Making Lua scripts run outside Skyrim
:: Find processabe Lua files
for %%i IN (*.lua) do (
    (Echo "%%i" | find /i "__" 1>NUL) || (
       lua __debug.lua d %%i
    )
)
pause
