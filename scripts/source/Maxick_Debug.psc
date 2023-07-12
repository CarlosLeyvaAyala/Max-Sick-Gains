Scriptname Maxick_Debug extends Quest

import Maxick_Utils
Maxick_Events Property ev Auto

int _lvlNone = 1
int _lvlCrit = 2
int _lvlInfo = 3
int _lvlVerb = 4
int _loggingLvl = 1
int _lvlOptim = -1
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
{_Was Testing mode enabled?_ Read only.}
  bool Function Get()
    return _testMode
  EndFunction
EndProperty

; Log with no regard of logging level.
; Use sparsely.
Function Log(string msg)
  If msg
    MiscUtil.PrintConsole("[Maxick] " + msg)
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

; Log as optimization.
;
; This mode is used exclusively by developers and should be enabled at compile time
; in `Maxick_Debug.OnGameReload()` by setting `_InitFromMcm(true)`.
;
; ***NEVER RELEASE THIS MOD WITH OPTIMIZATION LOGGING ACTIVATED***.
Function LogOptim(string msg)
  If _loggingLvl == _lvlOptim
    Log(msg)
  EndIf
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

Function OnGameReload()

EndFunction

; Initializes data from MCM settings. Used so the player doesn't have to configure this
; mod for each new stealthy archer they create.
;
; Logging at optimization level is done at compile time because this doesn't concern
; users at all.
Function _InitFromMcm(bool setOptimizationLvl = false)

EndFunction

; Dummy event. Used to make sure the logging level was correctly sent to addons.
Event OnGetLoggingLvl(string _, string __, float lvl, Form ___)
  LogVerb("Logging level was correctly sent: " + lvl as int)
EndEvent

; Called from MCM Helper when the user changed the logging level.
Function SetLoggingLvl(int lvl)

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
  _lvlOptim = -1
EndFunction

; Log at certain level.
Function _LogLvl(string msg, int lvl)
  If _loggingLvl >= lvl
    Log(msg)
  EndIf
EndFunction
