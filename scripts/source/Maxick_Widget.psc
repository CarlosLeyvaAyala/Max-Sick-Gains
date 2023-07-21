Scriptname Maxick_Widget extends Quest
{Deals with everything related to display status information to the player.}

import Maxick_Utils
import DM_Utils

Maxick_Debug Property md Auto
Maxick_MCM Property mcmHandler Auto
Maxick_Events Property ev Auto

int _updateInterval = 2
int _flashNormal = 0xffffff     ; White
int _flashDanger = 0xff6d01     ; Orange
int _flashUp = 0x4f8a35         ; Green
int _flashWarning = 0xffd966    ; Gold
int _flashDown = 0xcc0000       ; Dark red
int _flashCritical = 0xff0000   ; Red

bool _hidden = false
int _iconSize = 20
iWant_Widgets Property iWidgets Auto

;>========================================================
;>===                 INITIALIZATION                 ===<;
;>========================================================

Function OnGameReload()
  _RegisterEvents()
EndFunction

Function _RebuildIcons()
  ; int meterW = mcmHandler.GetModSettingFloat("fW:Widget") as int

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

  ; iWidgets.drawShapeLine(line, (Gains.X - meterW + _iconSize) as int, (Gains.Y -_iconSize - 5) as int, _iconSize + 5, 0)
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
  RegisterForModEvent("MaxickWidgetSetStageName", "OnMaxickSetStageName")
  RegisterForModEvent("MaxickWidgetSetMeters", "OnMaxickSetMeters")
EndFunction

Event OniWantWidgetsReset(String eventName, String strArg, Float numArg, Form sender)
  If eventName == "iWantWidgetsReset"
      iWidgets = sender As iWant_Widgets
  EndIf
  md.Log("========================================================")
  md.Log("Maxick Widget Reset")
  md.Log("========================================================")
  
  _ResetWidget()
EndEvent

string _stage = ""

Event OnMaxickSetStageName(string _, string stage, float ____, Form ___)
  _stage = stage

  if _widgetReady 
    _ChangeFitnessStage(stage)
  endIf
EndEvent

; Gets the starting index for a meter data got from `OnMaxickSetMeters`
int Function _meterArrayStartFromData(int meterNumber)
  ; `4` is the number of variables per meter sent by typescript
  return (meterNumber - 1) * 4
EndFunction

; Sets up meters size and positions as coming from the configuration app.
; `data` contains all the info in the form 
;     `x1|y1|width1|height1|x2|y2|width2|height2|x3|y3|width3|height3`
; 
;@NOTE: Change `_meterArrayStartFromData` if the number of variables sent by typescript ever changes.
Event OnMaxickSetMeters(string _, string data, float ____, Form ___)
  string[] d = StringUtil.Split(data, "|")

  int m = _meterArrayStartFromData(1)
  GainsMeter.X = d[m] as int
  GainsMeter.Y = d[m + 1] as int

  m = _meterArrayStartFromData(2)
  TrainingMeter.X = d[m] as int
  TrainingMeter.Y = d[m + 1] as int

  m = _meterArrayStartFromData(3)
  InactivityMeter.X = d[m] as int
  InactivityMeter.Y = d[m + 1] as int

  if _widgetReady 
    GainsMeter.MoveToXY()
    TrainingMeter.MoveToXY()
    InactivityMeter.MoveToXY()
  endIf
EndEvent

;>========================================================
;>===                  iWant SETUP                   ===<;
;>========================================================

bool _widgetReady = false
int _text = -1
int _textShadow = -1

Maxick_MeterGains Property GainsMeter Auto
Maxick_MeterTraining Property TrainingMeter Auto
Maxick_MeterInactivity Property InactivityMeter Auto
Maxick_TextFitStage Property FitStage Auto

Function _ResetWidget()
  _widgetReady = false
  int vGap = 14
  int x = 1206
  int y = 292 - vGap ; FIXME: Get fitness stage position from typescript
  
  ; =======================
  _ShowFitnessStage(x, y, _stage)
  
  ; =======================
  GainsMeter.ResetMeter(iWidgets)
  TrainingMeter.ResetMeter(iWidgets)
  InactivityMeter.ResetMeter(iWidgets)

  _widgetReady = true
  
  if _stage == ""
    ; Ask the SP plugin for the stage name
    SendModEvent("MaxickWidgetAskedForStageName")
  endIf
EndFunction

Function _ShowFitnessStage(int x, int y, string name)
  int size = 18
  string font = "$EverywhereFont"

  ; Shadow
  int s = iWidgets.loadText(name, font, size)
  iWidgets.setPos(s, x + 1, y + 1)
  iWidgets.setRGB(s, 0, 0, 0)
  iWidgets.setVisible(s)  
  _textShadow = s
  
  int t = iWidgets.loadText(name, font, size)
  iWidgets.setPos(t, x, y)
  iWidgets.setRGB(t, 255, 255, 255)
  iWidgets.setVisible(t)  
  _text = t
EndFunction

Function _ChangeFitnessStage(string stage)
  iWidgets.setText(_text, stage)
  iWidgets.setText(_textShadow, stage)
EndFunction


;>========================================================
;>===              SET, BUT DON'T FLASH              ===<;
;>========================================================

; Sets the value but doesn't flash. That's what `OnGainsDelta` and `_CatabolicFlash` are for.
Event OnGains(string _, string __, float val, Form ___)
  md.LogVerb("Widget got gains: " + val)
  GainsMeter.Percent = val as int
EndEvent

; Sets the value but doesn't flash. That's what `OnTrainDelta` and `_CatabolicFlash` are for.
Event OnTraining(string _, string __, float val, Form ___)
  md.LogVerb("Widget got training: " + val)
  
  ; This meter will consider anything 10 and above as 100%
  TrainingMeter.Percent = (val * 10.0 ) as int
EndEvent

; Sets the value but doesn't flash. That's what `_CatabolicFlash` is for.
Event OnInactivity(string _, string __, float val, Form ___)
  md.LogVerb("Widget got inactivity: " + val)
  InactivityMeter.Percent = val as int  
  int p = InactivityMeter.Percent
  
  ; This is the only exception to the "no flash" rule
  if  (p >= 80) && (p < 100)
    InactivityMeter.FlashNow(_flashDanger)
  endIf
EndEvent

;>========================================================
;>===              FLASH, BUT DON'T SET              ===<;
;>========================================================

; Flashes gains when conditions are right.
Function _FlashUp2(Maxick_iWantMeter meter, float delta)
  If (delta > 0) && (meter.Percent != 100)
    meter.FlashNow(_flashUp)
  EndIf
EndFunction

; Flashes losses when conditions are right.
Function _FlashDown2(Maxick_iWantMeter meter, float delta)
  If (delta < 0) && (meter.Percent != 0)
    meter.FlashNow(_flashDown)
  EndIf
EndFunction

; Flash according to delta.
Event OnGainsDelta(string _, string __, float delta, Form ___)
  md.LogVerb("Widget got gains delta " + delta)
  _FlashUp2(GainsMeter, delta)
  _FlashDown2(GainsMeter, delta)
EndEvent

; Flash according to delta.
Event OnTrainDelta(string _, string __, float delta, Form ___)
  md.LogVerb("Widget got training delta " + delta)
  _FlashUp2(TrainingMeter, delta)
  _FlashDown2(TrainingMeter, delta)
EndEvent

; Flashes meters while in catabolic state.
Function _CatabolicFlash()
  md.LogVerb("Widget is flashing catabolic losses.")
  GainsMeter.FlashNow(_flashDown)  
  TrainingMeter.FlashNow(_flashDown)  
  InactivityMeter.FlashNow(_flashCritical)  
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
    _FlashUp2(GainsMeter, delta)
  EndEvent
  
  ; No need to flash losses while in catabolism, since it will be done periodically, anyway.
  Event OnTrainDelta(string _, string __, float delta, Form ___)
    md.LogVerb("Widget got training delta " + delta)
    _FlashUp2(TrainingMeter, delta)
  EndEvent
EndState

;>========================================================
;>===                   DISPLAYING                   ===<;
;>========================================================

Function Toggle()
  _hidden = !_hidden
  float fadeTime = 0.5
  ; If _hidden
  ;   Gains.FadeTo(0.0, fadeTime)
  ;   Training.FadeTo(0.0, fadeTime)
  ;   Inactivity.FadeTo(0.0, fadeTime)
  ; Else
  ;   Gains.FadeTo(100.0, fadeTime)
  ;   Training.FadeTo(100.0, fadeTime)
  ;   Inactivity.FadeTo(100.0, fadeTime)
  ; EndIf
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
