Scriptname Maxick_Debug extends Quest

import Maxick_Utils

int _lvlNone = 1
int _lvlCrit = 2
int _lvlInfo = 3
int _lvlVerb = 4
int _loggingLvl = 1
bool _testMode = false

int Property loggingLvl Hidden
{Logging level the player wants.}
  int Function Get()
    return _loggingLvl
  EndFunction
EndProperty

bool Property testMode Hidden
{Was test mode enabled?}
  bool Function Get()
    return _testMode
  EndFunction
EndProperty

Function OnGameReload()
  _LoadData()
EndFunction

; Loads data from generated config file.
Function _LoadData()
  int vals = JValue.readFromFile(genCfg())
  _testMode = JMap.getInt(vals, "testMode") as bool
  _loggingLvl = JMap.getInt(vals, "loggingLvl")
  _lvlNone = JMap.getInt(vals, "logLvl_None")
  _lvlCrit = JMap.getInt(vals, "logLvl_Critical")
  _lvlInfo = JMap.getInt(vals, "logLvl_Info")
  _lvlVerb = JMap.getInt(vals, "logLvl_Verbose")
EndFunction

; Log with no regarding of logging level.
Function Log(string msg)
  If msg
    MiscUtil.PrintConsole("[Makicx] " + msg)
  EndIf
EndFunction

; Log at certain level.
Function _LogLvl(string msg, int lvl)
  If _loggingLvl >= lvl
    Log(msg)
  EndIf
EndFunction

; Log as critical.
Function LogCrit(string msg)
  _LogLvl(msg, _lvlCrit)
EndFunction

; Log as info.
Function LogInfo(string msg)
  _LogLvl(msg, _lvlInfo)
EndFunction

; Log as verbose.
Function LogVerb(string msg)
  _LogLvl(msg, _lvlVerb)
EndFunction
