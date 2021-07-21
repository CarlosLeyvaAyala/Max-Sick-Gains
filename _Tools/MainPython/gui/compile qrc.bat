@echo off
cd %~dp0
pyrcc5 "%~nx1" -o "..\%~n1_rc.py"
pause
