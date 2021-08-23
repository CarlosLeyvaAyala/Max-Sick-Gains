Scriptname Maxick_Widget extends Quest

import Maxick_Utils

Maxick_Debug Property md Auto
Maxick_EventNames Property ev Auto
Maxick_Meter01 Property Gains Auto
Maxick_Meter02 Property Training Auto
Maxick_Meter03 Property Inactivity Auto

int _updateInterval = 5
int _flashNormal
int _flashDanger
int _flashUp
int _flashWarning
int _flashDown
int _flashCritical

;>========================================================
;>===                 INITIALIZATION                 ===<;
;>========================================================

Function OnGameReload()
  _LoadData()
  _RegisterEvents()
EndFunction

; Gets data from Lua.
Function _LoadData()
  int data = JValue.readFromFile(widgetFile())
  JValue.evalLuaObj(data, "return maxick.InitWidget(jobject)")
  _InitWidget(data)
  Gains.LoadData(data)
  Training.LoadData(data)
  Inactivity.LoadData(data)
EndFunction

Function _InitWidget(int data)
  _flashNormal = JMap.getInt(data, "normal")
  _flashDanger = JMap.getInt(data, "danger")
  _flashUp = JMap.getInt(data, "up")
  _flashWarning = JMap.getInt(data, "warning")
  _flashDown = JMap.getInt(data, "down")
  _flashCritical = JMap.getInt(data, "critical")

  _updateInterval = JMap.getInt(data, "widgetRefresh", 10)
  SendModEvent(ev.UPDATE_INTERVAL, "", _updateInterval)
EndFunction

Function _RegisterEvents()
  RegisterForModEvent(ev.GAINS, "OnGains")
EndFunction

Event OnGains(string _, string __, float aGains, Form ___)
  md.LogVerb("Widget got gains " + aGains)
  Gains.Percent = aGains / 100
EndEvent
