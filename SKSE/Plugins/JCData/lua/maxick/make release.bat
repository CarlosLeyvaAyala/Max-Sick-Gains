@echo off
Title Making Lua scripts run inside Skyrim
:: Find processabe Lua files
for %%i IN (*.lua) do (
    (Echo "%%i" | find /i "__" 1>NUL) || (
       lua __debug.lua r %%i
    )
)
pause
