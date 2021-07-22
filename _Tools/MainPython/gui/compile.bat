:: Double click this file to compile GUI and resources

@echo off
cd %~dp0
"compile gui.bat" mainWindow.ui
"compile qrc.bat" res.qrc
pause
