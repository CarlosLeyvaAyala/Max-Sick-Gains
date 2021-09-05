Scriptname Maxick_Widget extends Quest
{Deals with everything related to display status information to the player.}

import Maxick_Utils
import DM_Utils

Maxick_Debug Property md Auto
Maxick_MCM Property mcmHandler Auto
Maxick_Events Property ev Auto
Maxick_Meter01 Property Gains Auto
Maxick_Meter02 Property Training Auto
Maxick_Meter03 Property Inactivity Auto

int _updateInterval = 2
int _flashNormal = 0xffffff     ; White
int _flashDanger = 0xff6d01     ; Orange
int _flashUp = 0x4f8a35         ; Green
int _flashWarning = 0xffd966    ; Gold
int _flashDown = 0xcc0000       ; Dark red
int _flashCritical = 0xff0000   ; Red

bool _hidden = false
int _iconSize = 20
iWant_Widgets iWidgets

;>========================================================
;>===                 INITIALIZATION                 ===<;
;>========================================================

Function OnGameReload()
  iWidgets = iWantWidgetsHandle()
  mcmHandler.UpdateWidget()
  _RegisterEvents()
EndFunction

; Gets data from Lua for setting the meters.
; This function is called by `Maxick_MCM.UpdateWidget()`.
Function SetAppearanceance(float x, float y, float meterH, float meterW, float vGap, int hAlign, int vAlign)
  md.LogVerb("Widget.SetAppearanceance()")
  md.LogVerb(x + ", " + y + ", " + meterH + ", " + meterW + ", " + vGap + ", " + hAlign + ", " + vAlign)
  int data = LuaTable("maxick.WidgetMeterPositions", x, y, meterH, vGap, hAlign + 1, vAlign + 1)
  ; LuaDebugTable(data, "widget")
  Gains.SetData(data, meterH, meterW, hAlign + 1, vAlign + 1)
  Training.SetData(data, meterH, meterW, hAlign + 1, vAlign + 1)
  Inactivity.SetData(data, meterH, meterW, hAlign + 1, vAlign + 1)

  ; Reconstruir iconos
  ; _RebuildIcons()
EndFunction

Function _RebuildIcons()
  int meterW = mcmHandler.GetModSettingFloat("fW:Widget") as int

  int playerStage = _AddIcon("fat", 220, 125)
  int z = JDB.solveObj(".maxick.widgetIcons")
  int numIcons = JMap.count(z) + 1


  int [] line = new int[1]
  line[0] = playerStage

  int i = 1
  While (i < line.Length)
    line[i] = _AddIcon("tired", 255, 220)
    i += 1
  EndWhile
  ; Int myApple = _AddIcon("tired", 255, 220)
  ; Int skull = _AddIcon("injury", 255, 25, 25)
  ; line[1] = myApple
  ; line[2] = skull

  iWidgets.drawShapeLine(line, (Gains.X - meterW + _iconSize) as int, (Gains.Y -_iconSize - 5) as int, _iconSize + 5, 0)
EndFunction

int Function _AddIcon(string name, int r = 0, int g = 0, int b = 0, bool fromLib = false)
  int icon
  If fromLib
    icon = iWidgets.loadLibraryWidget(name)
  Else
    icon = iWidgets.loadWidget("widgets/maxick/" + name + ".dds")
  EndIf
  iWidgets.setZoom(icon, _iconSize, _iconSize)
  iWidgets.setRGB(icon, r, g, b)
  iWidgets.setVisible(icon)
  return icon
EndFunction

Function _InitWidget()
  _updateInterval = 2
  md.LogVerb("Widget update interval: " + _updateInterval)
EndFunction

Function _RegisterEvents()
  md.LogVerb("Registering widget events")
  RegisterForModEvent(ev.GAINS, "OnGains")
  RegisterForModEvent(ev.TRAINING, "OnTraining")
  RegisterForModEvent(ev.INACTIVITY, "OnInactivity")
  RegisterForModEvent(ev.GAINS_CHANGE, "OnGainsDelta")
  RegisterForModEvent(ev.TRAINING_CHANGE, "OnTrainDelta")
  RegisterForModEvent(ev.CATABOLISM_START, "OnCatabolicEnter")
  RegisterForModEvent(ev.CATABOLISM_END, "OnCatabolicExit")
  RegisterForModEvent(ev.PLAYER_STAGE_DELTA, "OnChangeStage")
  RegisterForModEvent("iWantWidgetsReset", "OniWantWidgetsReset")
EndFunction

Event OniWantWidgetsReset(string _, string __, float ___, Form sender)
  md.Log("========================================================")
  md.LogVerb("Initializing iWantWidget")

EndEvent


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

; Flashes gains when conditions are right.
Function _FlashUp(Maxick_MeterBase meter, float delta)
  If (delta > 0) && (meter.Percent != 1.0)
    meter.FlashNow(_flashUp)
  EndIf
EndFunction

; Flashes losses when conditions are right.
Function _FlashDown(Maxick_MeterBase meter, float delta)
  If (delta < 0) && (meter.Percent != 0)
    meter.FlashNow(_flashDown)
  EndIf
EndFunction

; Flash according to delta.
Event OnGainsDelta(string _, string __, float delta, Form ___)
  md.LogVerb("Widget got gains delta " + delta)
  _FlashUp(Gains, delta)
  _flashDown(Gains, delta)
EndEvent

; Flash according to delta.
Event OnTrainDelta(string _, string __, float delta, Form ___)
  md.LogVerb("Widget got training delta " + delta)
  _FlashUp(Training, delta)
  _FlashDown(Training, delta)
EndEvent

; Flashes meters while in catabolic state.
Function _CatabolicFlash()
  md.LogVerb("Widget is flashing catabolic losses.")
  Gains.FlashNow(_flashDown)
  Training.FlashNow(_flashDown)
  Inactivity.FlashNow(_flashCritical)
  RegisterForSingleUpdate(2)
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
  Event OnGainsDelta(string _, string __, float delta, Form ___)
    md.LogVerb("Widget got gains delta " + delta)
    _FlashUp(Gains, delta)
  EndEvent

  ; No need to flash losses while in catabolism, since it will be done periodically, anyway.
  Event OnTrainDelta(string _, string __, float delta, Form ___)
    md.LogVerb("Widget got training delta " + delta)
    _FlashUp(Training, delta)
  EndEvent
EndState

;>========================================================
;>===                   DISPLAYING                   ===<;
;>========================================================

Function Toggle()
  _hidden = !_hidden
  float fadeTime = 0.5
  If _hidden
    Gains.FadeTo(0.0, fadeTime)
    Training.FadeTo(0.0, fadeTime)
    Inactivity.FadeTo(0.0, fadeTime)
  Else
    Gains.FadeTo(100.0, fadeTime)
    Training.FadeTo(100.0, fadeTime)
    Inactivity.FadeTo(100.0, fadeTime)
  EndIf
EndFunction

Event OnChangeStage(string _, string msg, float delta, Form ___)
  int d = delta as int
  md.LogVerb("Widget got Player Stage change: " + d)
  If d > 0
    Debug.Notification("Your hard training has paid off!")
  ElseIf d < 0
    Debug.Notification("You lost gains, but don't fret; you can always come back.")
  Else
    return
  EndIf
  If msg
    Debug.Notification(msg)
  EndIf
EndEvent
