Scriptname Maxick_Debug extends Quest

import Maxick_Utils
Maxick_Events Property ev Auto

int _lvlNone = 1
int _lvlCrit = 2
int _lvlInfo = 3
int _lvlVerb = 4
int _loggingLvl = 1
bool _testMode = false


; !  ██╗   ██╗███████╗███████╗    ████████╗██╗  ██╗███████╗███████╗███████╗
; !  ██║   ██║██╔════╝██╔════╝    ╚══██╔══╝██║  ██║██╔════╝██╔════╝██╔════╝
; !  ██║   ██║███████╗█████╗         ██║   ███████║█████╗  ███████╗█████╗
; !  ██║   ██║╚════██║██╔══╝         ██║   ██╔══██║██╔══╝  ╚════██║██╔══╝
; !  ╚██████╔╝███████║███████╗       ██║   ██║  ██║███████╗███████║███████╗
; !   ╚═════╝ ╚══════╝╚══════╝       ╚═╝   ╚═╝  ╚═╝╚══════╝╚══════╝╚══════╝

int Property loggingLvl Hidden
{Logging level the player wants. Read only.}
  int Function Get()
    return _loggingLvl
  EndFunction
EndProperty

bool Property testMode Hidden
{Was Testing mode enabled?}
  bool Function Get()
    return _testMode
  EndFunction
EndProperty

; Log with no regard of logging level.
; Use sparsely.
Function Log(string msg)
  If msg
    MiscUtil.PrintConsole("[Makicx] " + msg)
  EndIf
EndFunction

; Log as critical.
; Critical info are errors and things that require inmediate attention.
Function LogCrit(string msg)
  _LogLvl(msg, _lvlCrit)
EndFunction

; Log as info.
; This is detailed info meant to be read by players so they know what's happening with their
; settings.
Function LogInfo(string msg)
  _LogLvl(msg, _lvlInfo)
EndFunction

; Log as verbose.
; Really detailed info that is meant to be read only by developers for debugging purposes.
Function LogVerb(string msg)
  _LogLvl(msg, _lvlVerb)
EndFunction


; !  ██╗ ██████╗ ███╗   ██╗ ██████╗ ██████╗ ███████╗    ████████╗██╗  ██╗███████╗███████╗███████╗
; !  ██║██╔════╝ ████╗  ██║██╔═══██╗██╔══██╗██╔════╝    ╚══██╔══╝██║  ██║██╔════╝██╔════╝██╔════╝
; !  ██║██║  ███╗██╔██╗ ██║██║   ██║██████╔╝█████╗         ██║   ███████║█████╗  ███████╗█████╗
; !  ██║██║   ██║██║╚██╗██║██║   ██║██╔══██╗██╔══╝         ██║   ██╔══██║██╔══╝  ╚════██║██╔══╝
; !  ██║╚██████╔╝██║ ╚████║╚██████╔╝██║  ██║███████╗       ██║   ██║  ██║███████╗███████║███████╗
; !  ╚═╝ ╚═════╝ ╚═╝  ╚═══╝ ╚═════╝ ╚═╝  ╚═╝╚══════╝       ╚═╝   ╚═╝  ╚═╝╚══════╝╚══════╝╚══════╝

Event OnInit()
  _InitFromMcm()
EndEvent

; Initializes data from MCM settings. Used so the player doesn't have to configure this
; mod each new stealthy archer they create.
Function _InitFromMcm()
  SetLoggingLvl(MCM.GetModSettingInt("Max Sick Gains", "iLogLvl:Other"))
EndFunction

Function OnGameReload()
  _InitFromMcm()
  Log("Current logging level: " + _loggingLvl)
  RegisterForModEvent(ev.LOGGING_LVL, "OnGetLoggingLvl")
  _LoadData()
EndFunction

; Dummy event. Used to make sure the logging level was correctly sent to addons.
Event OnGetLoggingLvl(string _, string __, float lvl, Form ___)
  LogVerb("Logging level was correctly sent: " + lvl)
EndEvent

; Called from MCM Helper when the user changed the logging level.
Function SetLoggingLvl(int lvl)
  lvl += 1
  Log("Logging level was set to " + lvl as int)
  _loggingLvl = lvl as int
  SetLuaLoggingLvl()
  SendModEvent(ev.LOGGING_LVL, "", _loggingLvl)
EndFunction

; Tells Lua which is the logging level.
Function SetLuaLoggingLvl()
  JLua.evalLuaInt("maxick.SetLoggingLvl(" + _loggingLvl + ")", 0)
EndFunction

; Bridges debug data between Lua and Papyrus.
Function _LoadData()
  _testMode = JLua.evalLuaInt("return maxick.testingMode", 0) as bool
  SetLuaLoggingLvl()
  _lvlNone = 1
  _lvlCrit = 2
  _lvlInfo = 3
  _lvlVerb = 4
EndFunction

; Log at certain level.
Function _LogLvl(string msg, int lvl)
  If _loggingLvl >= lvl
    Log(msg)
  EndIf
EndFunction
