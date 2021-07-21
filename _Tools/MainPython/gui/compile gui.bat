@echo off
cd %~dp0
pyuic5 -o "%~n1.py" "%~nx1"
pause
