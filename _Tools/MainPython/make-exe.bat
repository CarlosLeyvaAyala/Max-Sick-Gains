:: Double click this file to make exe app

@echo off
cd %~dp0
pyinstaller --onefile --noconsole main_01.py -i "gui\icon\MaxSickGains.ico" -n "MaxSicKGains"
pause
