@echo off
cd %~dp0
echo %~dp0
rem pushd %~dp0
pyuic5 -o "%~n1.py" "%~nx1"
rem pyuic5 -x -o "%~n1.py" "%~nx1"
pause
