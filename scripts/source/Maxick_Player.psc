Scriptname Maxick_Player extends Quest
{Player management}

import Maxick_Utils

Maxick_Main Property main Auto
Maxick_ActorAppearance Property looksHandler Auto
Actor Property player Auto
Maxick_Debug Property md Auto
Maxick_EventNames Property ev Auto

int hkGains0
int hkGains100
int hkAdvance
int hkRegress
int hkNextLvl
int hkPrevLvl
int hkSlideshow

float _gains = 0.0
int _stage = 1

Event OnInit()
  OnGameReload()
EndEvent

Function OnGameReload()
  If md.testMode
    GotoState("TestingMode")
  Else
    GotoState("")
  EndIf
  RegisterEvents()
  SetHotkeys()
EndFunction

Function RegisterEvents()
  RegisterForModEvent(ev.TRAIN, "OnTrain")
  RegisterForModEvent(ev.UPDATE_INTERVAL, "OnGetUpdateInterval")
  RegisterForModEvent("Maxick_Sleep", "OnSleep")
EndFunction

Event OnGetUpdateInterval(string _, string __, float interval, Form ___)
  md.LogVerb("Got update interval: " + interval)
EndEvent

Function _SetGains(float value)
  _gains = value
  SendModEvent(ev.GAINS, "", value)
EndFunction

;>========================================================
;>===                  TESTING MODE                  ===<;
;>========================================================

; How much time (seconds) between steps in Slideshow view.
float _slStepTime = 0.5

; Stops the slideshow.
Function _SlideshowStop()
  GotoState("TestingMode")
  UnregisterForUpdate()
  Debug.Notification("Last stage reached")
EndFunction

; Goes to the next stage of the slideshow. Stops if reached the last Player stage.
Function _SlideShowNextStage()
  int old = _stage
  _stage = JValue.evalLuaInt(0, "return maxick.SlideshowNextStage(" + _stage + ")")
  If _stage < 1
    ; Reached last stage
    _stage = old
    _SlideshowStop()
    _SetGains(100.0)
  Else
    _SetGains(0.0)
    Debug.Notification(JValue.evalLuaStr(0, "return maxick.SlideshowStageMsg(" + _stage + ")"))
  EndIf
EndFunction

Function _SlideshowPreviousStage()
  If _stage <= 1
    Debug.Notification("First stage reached")
    _stage = 1
    _SetGains(0.0)
  Else
    _SetGains(100.0)
    _stage -= 1
    Debug.Notification(JValue.evalLuaStr(0, "return maxick.SlideshowStageMsg(" + _stage + ")"))
  EndIf
EndFunction

; Setups the hotkeys that will be used in testing mode.
Function SetHotkeys()
  ;FIXME: Initialize elsewhere
  hkGains0 = 203
  hkGains100 = 205
  hkPrevLvl = 208
  hkNextLvl = 200
  hkRegress = 75
  hkAdvance = 77
  hkSlideshow = 28
  RegisterForKey(hkGains0)
  RegisterForKey(hkGains100)
  RegisterForKey(hkPrevLvl)
  RegisterForKey(hkNextLvl)
  RegisterForKey(hkRegress)
  RegisterForKey(hkAdvance)
  RegisterForKey(hkSlideshow)
EndFunction

Function _SlideshowAdvance(float delta)
  _SetGains(_gains + delta)
  If ((_gains > 100.0) && (delta > 0))
    _SlideShowNextStage()
  ElseIf ((_gains < 0.0) && (delta < 0))
    _SlideshowPreviousStage()
  EndIf
  ChangeAppearance()
EndFunction

Event OnKeyDown(Int KeyCode)
  md.LogVerb("Hotkeys only enabled while in testing mode.")
EndEvent

State TestingMode
  Event OnKeyDown(Int KeyCode)
    If KeyCode == hkGains0
      If _gains <= 0.0
        _SlideshowPreviousStage()
      Else
        _SetGains(0.0)
      EndIf
      ChangeAppearance()
    EndIf
    If KeyCode == hkGains100
      If _gains >= 100.0
        _SlideShowNextStage()
      Else
        _SetGains(100.0)
      EndIf
      ChangeAppearance()
    EndIf
    If KeyCode == hkNextLvl
      _SlideShowNextStage()
      ChangeAppearance()
    EndIf
    If KeyCode == hkPrevLvl
      _SlideshowPreviousStage()
      ChangeAppearance()
    EndIf
    If KeyCode == hkAdvance
      _SlideshowAdvance(5.0)
      ChangeAppearance()
    EndIf
    If KeyCode == hkRegress
      _SlideshowAdvance(-5.0)
      ChangeAppearance()
    EndIf
    If KeyCode == hkSlideshow
      _SetGains(0.0)
      ; TODO: Send event when changing stage
      _stage = 1
      ChangeAppearance()
      Debug.Notification("Started slideshow")
      GotoState("Slideshow")
      RegisterForSingleUpdate(_slStepTime)
    EndIf
  EndEvent
EndState

State Slideshow
  Event OnUpdate()
    _SlideshowAdvance(10.0)
    RegisterForSingleUpdate(_slStepTime)
  EndEvent

  Event OnKeyDown(Int KeyCode)
    If KeyCode == hkSlideshow
      _SlideshowStop()
    EndIf
  EndEvent
EndState

;>========================================================
;>===                   APPEARANCE                   ===<;
;>========================================================

; Player got some training.
Event OnTrain(string _, string skillName, float __, Form sender)
  md.LogVerb("Skill level up: " + skillName)
EndEvent

; Player woke up.
Event OnSleep(string _, string __, float hoursSlept, Form ___)
  md.LogVerb("Hours slept: " + hoursSlept)
EndEvent

; Changes player appearance.
Function ChangeAppearance()
  int appearance = _GetAppearance()
  looksHandler.ChangeAppearance(player, appearance)
  ; Make head size obviously wrong when getting default values to help catch bugs.
  looksHandler.ChangeHeadSize(player, JMap.getFlt(appearance, "headSize", 2.2))
EndFunction

; Initializes the data that will be used to change appearance.
int Function _InitData()
  int data = JMap.object()

  ; Weight is irrelevant. It's only set so `looksHandler.ChangeAppearance` sets the
  ; Bodyslide preset.
  looksHandler.InitCommonData(data, player, 0, 1)

  JMap.setInt(data, "stage", _stage)       ; Current player stage
  JMap.setFlt(data, "training", 0)
  JMap.setFlt(data, "gains", _gains)
  JMap.setFlt(data, "headSize", 0.0)

  ; Events
  JMap.setInt(data, "evChangeStage", 0)

  return data
EndFunction

; Gets the player appearance from Lua.
int Function _GetAppearance()
  return JValue.evalLuaObj(_InitData(), "return maxick.ChangePlayerAppearance(jobject)")
EndFunction
