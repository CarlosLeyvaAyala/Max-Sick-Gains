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
  _flashNormal = JValue.solveInt(data, ".flashColors.normal", 16777215)
  _flashDanger = JValue.solveInt(data, ".flashColors.danger", 16739585)
  _flashUp = JValue.solveInt(data, ".flashColors.up", 5212725)
  _flashWarning = JValue.solveInt(data, ".flashColors.warning", 16767334)
  _flashDown = JValue.solveInt(data, ".flashColors.down", 13369344)
  _flashCritical = JValue.solveInt(data, ".flashColors.critical", 16711680)

  _updateInterval = JMap.getInt(data, "widgetRefresh", 10)
  SendModEvent(ev.UPDATE_INTERVAL, "", _updateInterval)
EndFunction

Function _RegisterEvents()
  RegisterForModEvent(ev.GAINS, "OnGains")
  RegisterForModEvent(ev.TRAINING, "OnTraining")
  RegisterForModEvent(ev.INACTIVITY, "OnInactivity")
  ; TODO: OnGainsDelta
  RegisterForModEvent(ev.TRAINING_CHANGE, "OnTrainDelta")
  RegisterForModEvent(ev.CATABOLISM_START, "OnCatabolicEnter")
  RegisterForModEvent(ev.CATABOLISM_END, "OnCatabolicExit")
EndFunction

;>========================================================
;>===              SET, BUT DON'T FLASH              ===<;
;>========================================================

; Sets the value but doesn't flash. That's what `OnGainsDelta` and `_CatabolicFlash` are for.
Event OnGains(string _, string __, float val, Form ___)
  md.LogVerb("Widget got gains: " + val)
  Gains.Position = val
EndEvent

; Sets the value but doesn't flash. That's what `OnTrainDelta` and `_CatabolicFlash` are for.
Event OnTraining(string _, string __, float val, Form ___)
  md.LogVerb("Widget got training: " + val)
  ; This meter will consider anything 10 and above as 100%
  Training.Percent = val / 10.0
EndEvent

; Sets the value but doesn't flash. That's what `_CatabolicFlash` is for.
Event OnInactivity(string _, string __, float val, Form ___)
  md.LogVerb("Widget got inactivity: " + val)
  Inactivity.Position = val
  ; This is the only exception to the "no flash" rule
  If (Inactivity.Percent >= 0.8) && (Inactivity.Percent < 1)
    Inactivity.FlashNow(_flashDanger)
  EndIf
EndEvent

;>========================================================
;>===              FLASH, BUT DON'T SET              ===<;
;>========================================================

Function _FlashGains(Maxick_MeterBase meter, float delta)
  If delta > 0
    meter.FlashNow(_flashUp)
  EndIf
EndFunction

; Flash according to delta.
Event OnTrainDelta(string _, string __, float delta, Form ___)
  md.LogVerb("Widget got training delta " + delta)
  _FlashGains(Training, delta)
  If delta < 0
    Training.FlashNow(_flashDown)
  EndIf
EndEvent

; Flashes meters while in catabolic state.
Function _CatabolicFlash()
  md.LogVerb("Widget is flashing catabolic losses.")
  Gains.FlashNow(_flashDown)
  Training.FlashNow(_flashDown)
  Inactivity.FlashNow(_flashCritical)
  RegisterForSingleUpdate(_updateInterval)
EndFunction

Event OnCatabolicEnter(string _, string __, float ____, Form ___)
  md.LogVerb("Widget will flash catabolic losses.")
  GotoState("CatabolicState")
  _CatabolicFlash()
EndEvent

Event OnCatabolicExit(string _, string __, float ____, Form ___)
  md.LogVerb("Widget will stop flashing losses.")
  GotoState("")
EndEvent

Event OnUpdate()
  UnregisterForUpdate()
EndEvent

State CatabolicState
  Event OnUpdate()
    _CatabolicFlash()
  EndEvent

  ; No need to flash losses while in catabolism, since it will be done periodically, anyway.
  Event OnTrainDelta(string _, string __, float delta, Form ___)
    md.LogVerb("Widget got training delta " + delta)
    _FlashGains(Training, delta)
  EndEvent
EndState

;>========================================================
;>===                   DISPLAYING                   ===<;
;>========================================================
