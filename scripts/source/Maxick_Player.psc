; Naming conventions:
; Names starting with a single _ are meant to be private. Never call them from outside.
; Names starting with double __ should never be called by themselves.
;   They are part of larger calculations that needed to be done apart for sake of clarity.
;   Wouldn't be necessary to use them if Papyrus wasn't so limited.

Scriptname Maxick_Player extends Quest
{Player management}

import Maxick_Utils
import DM_Utils

Maxick_Main Property main Auto
Maxick_ActorAppearance Property looksHandler Auto
Actor Property player Auto
Maxick_Debug Property md Auto
Maxick_EventNames Property ev Auto

;>========================================================
;>===                  PLAYER DATA                   ===<;
;>========================================================

;> Public values

; All these were added as functions because constants get baked into game saves.
; Good look trying to update those without making the new version requiring a new game.

; How much ***HUMAN HOURS*** must pass without training before you enter _catabolic state_.
float Function InactivityTimeLimit() Global
  return 48.0
EndFunction

; How much `training` you can accumulate.
; Beyond this point, training skills will still affect `inactivity`, but won't contribute to `training` anymore.
float Function MaxTraining() Global
  return 12.0
EndFunction

; How many training points you will lose a day.
; Notice this is a fixed number, not a percent.
float Function TrainingDecay() Global
  return JValue.evalLuaFlt(0, "return maxick.trainingDecay")
EndFunction

; How many training points you will lose when inactive.
; Notice this is a fixed number, not a percent.
float Function TrainingCatabolism() Global
  return 0.5
EndFunction

;> Player variables used for calculations

float _gains = 0.0
; Tells the last time the player trained. Value is in ***GAME HOURS***.
float _lastTrained = 0.0
float _lastTrainedWithSacks = 0.0
float _training = 0.0
int _stage = 1
bool _isInCatabolic = false
int _pollingInterval = 10
float _lastPollingTime = 0.0

;> Hotkeys
int hkGains0
int hkGains100
int hkAdvance
int hkRegress
int hkNextLvl
int hkPrevLvl
int hkSlideshow

;>========================================================
;>===                     SETUP                      ===<;
;>========================================================

Event OnInit()
  OnGameReload()
  _lastTrained = Now()
  _lastPollingTime = Now()
EndEvent

Function OnGameReload()
  _EnterTestingMode()
  RegisterEvents()
  SetHotkeys()
EndFunction

; Enters testing mode if needed.
Function _EnterTestingMode()
  If md.testMode
    GotoState("TestingMode")
  Else
    GotoState("")
  EndIf
EndFunction

; Registers the events needed for this mod to work.
Function RegisterEvents()
  RegisterForModEvent(ev.TRAIN, "OnTrain")
  RegisterForModEvent(ev.GAINS_CHANGE, "OnGainsDelta")
  RegisterForModEvent(ev.TRAINING_CHANGE, "OnTrainDelta")
  RegisterForModEvent(ev.ACTIVITY_CHANGE, "OnInactivityDelta")
  RegisterForModEvent(ev.UPDATE_INTERVAL, "OnGetUpdateInterval")
  RegisterForModEvent(ev.SLEEP, "OnSleep")
EndFunction

; Gets the update interval to calculate losses.
Event OnGetUpdateInterval(string _, string __, float interval, Form ___)
  md.LogVerb("Got update interval: " + interval)
  _pollingInterval = interval as int
  _Poll()
EndEvent

;>========================================================
;>===              POLLING CALCULATIONS              ===<;
;>========================================================

; These are done each `n` seconds defined by the player when setting the
; widget refresh rate in the MCM.

Event OnUpdate()
  _Poll()
EndEvent

; Does the few calculations that need to be done every `<n>` seconds:
; - Training decay.
; - Losses by inactivity.
Function _Poll()
  md.LogVerb("Polling. Time: " + _pollingInterval)

  _InactivityCalculation()

  ; Decay and losses calculation
  int data = LuaTable("maxick.Poll", Now(), _lastPollingTime, _training, _gains, _stage, _isInCatabolic as int)
  _SetGains( JMap.getFlt(data, "newGains") )
  _SetTraining( JMap.getFlt(data, "newTraining") )
  _SetStage( JMap.getInt(data, "newStage") )
  _SendStageDelta( JMap.getInt(data, "stageDelta") )

  _lastPollingTime = Now()
  RegisterForSingleUpdate(_pollingInterval)
EndFunction

;>========================================================
;>===                    TRAINING                    ===<;
;>========================================================

;> Value setting

; Sets `gains` to some value and sends the mod event saying `gains` has a new value.
Function _SetGains(float value)
  _gains = value
  SendModEvent(ev.GAINS, "", _gains)
EndFunction

; Sets `training` and sends the notification.
Function _SetTraining(float value)
  _training = value
  SendModEvent(ev.TRAINING, "", _training)
EndFunction

; Sets `player stage` and sends the notification.
Function _SetStage(int value)
  _stage = value
  SendModEvent(ev.PLAYER_STAGE, "", _stage)
EndFunction

;> Other

; Sends a notification saying if player gained or lost a fitness lvl (_Player Stage_).
Function _SendStageDelta(int delta)
  If delta != 0
    md.LogInfo("Player changed stage by " + delta)
    SendModEvent(ev.PLAYER_STAGE_DELTA, "", delta)
  EndIf
EndFunction

; Calculates inactivity as a number in `[0..100]` and then tests if player entered _Catabolic State_.
Function _InactivityCalculation()
  ; Never allow inactivity get out of bounds
  _lastTrained = JValue.evalLuaFlt(0, "return maxick.HadActivity(" + Now() + ", " + _lastTrained +", 0)")

  float inactivityPercent = HourSpan(_lastTrained) / InactivityTimeLimit() * 100
  SendModEvent(ev.INACTIVITY, "", inactivityPercent)
  _CatabolicTest(inactivityPercent)
EndFunction

; Tests if player is in catabolic state and sends events accordingly.
Function _CatabolicTest(float inactivityPercent)
  md.LogVerb("Inactivity percent: " + inactivityPercent)
  bool old = _isInCatabolic
  ; Don't use 100 due to float and time imprecision
  _isInCatabolic = inactivityPercent >= 99.8
  If _isInCatabolic != old
    md.LogVerb("There was a change in catabolic state.")
    If _isInCatabolic
      md.LogVerb("Player entered catabolic state.")
      SendModEvent(ev.CATABOLISM_START, "", 1)
    Else
      md.LogVerb("Player got out from catabolic state.")
      SendModEvent(ev.CATABOLISM_END, "", 0)
    EndIf
  EndIf
EndFunction

;>========================================================
;>===               EVENTS FROM ADDONS               ===<;
;>========================================================

; Player woke up.
; - Set training.
; - Send gains delta.
Event OnSleep(string _, string __, float hoursSlept, Form ___)
  md.LogVerb("=====================================")
  md.LogVerb("Hours slept: " + hoursSlept)

  int data = LuaTable("maxick.OnSleep", hoursSlept, _training, _gains, _stage)
  _SetGains( JMap.getFlt(data, "newGains") )
  _SetTraining( JMap.getFlt(data, "newTraining") )
  _SetStage( JMap.getInt(data, "newStage") )
  _SendStageDelta( JMap.getInt(data, "stageDelta") )
  SendModEvent(ev.GAINS_CHANGE, "", JMap.getFlt(data, "gainsDelta"))
  md.LogVerb("=====================================")
EndEvent

; Player got direct `gains` from an addon.
Event OnGainsDelta(string _, string __, float delta, Form sender)
  If sender == self
    md.LogVerb("Maxick_Player script got an OnGainsDelta event that it send itself. Skipping value setting because that was already done.")
  EndIf
  md.LogVerb("Got gains change: " + delta)
  _SetGains(_gains + delta)
EndEvent

; Player got some training.
Event OnTrain(string _, string skillName, float __, Form ___)
  md.LogVerb("Skill level up: " + skillName)
  ; Get training for a skill from Lua.
  ; TODO: Clean this mess
  int data = JMap.object()
  JMap.setStr(data, "skill", skillName)
  JMap.setFlt(data, "training", 0.0)
  JMap.setFlt(data, "activity", 0.0)

  data = JValue.evalLuaObj(data, "return maxick.Train(jobject)")
  ev.SendTrainingAndActivity(skillName, JMap.getFlt(data, "training"), JMap.getFlt(data, "activity"))
EndEvent

; Got the value for which the `training` will change.
Event OnTrainDelta(string _, string __, float delta, Form ___)
  md.LogVerb("Training change: " + delta)
  If delta == 0
    return
  EndIf
  float nVal = _training + delta
  ; TODO: Make a CapTraining function in Lua
  float capped = JValue.evalLuaFlt(0, "return dmlib.forceRange(0, " + MaxTraining() + ")(" + nVal + ")")
  _SetTraining(capped)
EndEvent

; Got the value for which the `inactivity` will change.
Event OnInactivityDelta(string _, string __, float delta, Form ___)
  md.LogVerb("Inactivity change: " + delta)
  _lastTrained = JValue.evalLuaFlt(0, "return maxick.HadActivity(" + Now() + ", " + _lastTrained +", " + ToGameHours(delta) +")")
  _InactivityCalculation()
EndEvent

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
  ; FIXME: Toggle widget
  md.LogVerb("Hotkeys only enabled while in testing mode.")
EndEvent

; What to do when the `hkGains0` hotkey was pressed.
Function _HkGains0()
  If _gains <= 0.0
    _SlideshowPreviousStage()
  Else
    _SetGains(0.0)
  EndIf
  ChangeAppearance()
EndFunction

; What to do when the `hkGains100` hotkey was pressed.
Function _HkGains100()
  If _gains >= 100.0
    _SlideShowNextStage()
  Else
    _SetGains(100.0)
  EndIf
  ChangeAppearance()
EndFunction

; What to do when the `hkNextLvl` hotkey was pressed.
Function _HkNextLvl()
  _SlideShowNextStage()
  ChangeAppearance()
EndFunction

; What to do when the `hkPrevLvl` hotkey was pressed.
Function _HkPrevLvl()
  _SlideshowPreviousStage()
  ChangeAppearance()
EndFunction

; What to do when the `hkAdvance` hotkey was pressed.
Function _HkAdvance()
  _SlideshowAdvance(5.0)
  ChangeAppearance()
EndFunction

; What to do when the `hkRegress` hotkey was pressed.
Function _HkRegress()
  _SlideshowAdvance(-5.0)
  ChangeAppearance()
EndFunction

; What to do when the `hkSlideshow` hotkey was pressed.
Function _HkSlideshow()
  _SetGains(0.0)
  ; TODO: Send event when changing stage
  _stage = 1
  ChangeAppearance()
  Debug.Notification("Started slideshow")
  GotoState("Slideshow")
  RegisterForSingleUpdate(_slStepTime)
EndFunction

State TestingMode
  Event OnKeyDown(Int KeyCode)
    If KeyCode == hkGains0
      _HkGains0()
      return
    EndIf
    If KeyCode == hkGains100
      _HkGains100()
      return
    EndIf
    If KeyCode == hkNextLvl
      _HkNextLvl()
      return
    EndIf
    If KeyCode == hkPrevLvl
      _HkPrevLvl()
      return
    EndIf
    If KeyCode == hkAdvance
      _HkAdvance()
      return
    EndIf
    If KeyCode == hkRegress
      _HkRegress()
      return
    EndIf
    If KeyCode == hkSlideshow
      _HkSlideshow()
      return
    EndIf
  EndEvent

  Event OnUpdate()
    ; Losses and inactivity aren't calculated while in testing mode.
    UnregisterForUpdate()
  EndEvent

  Event OnTrain(string _, string ___, float __, Form ____)
    md.LogVerb("Can't train while testing")
  EndEvent

  Event OnTrainDelta(string _, string __, float delta, Form ___)
    md.LogVerb("Can't train while testing")
  EndEvent

  Event OnInactivityDelta(string _, string __, float delta, Form ___)
    md.LogVerb("Inactivity disabled while testing")
  EndEvent

  Event OnSleep(string _, string __, float ____, Form ___)
    md.LogVerb("Can't gain while testing")
  EndEvent

  Event OnGainsDelta(string _, string __, float delta, Form sender)
    md.LogVerb("Can't gain while testing")
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

  Event OnTrain(string _, string ___, float __, Form ____)
    md.LogVerb("Can't train while testing")
  EndEvent

  Event OnTrainDelta(string _, string __, float delta, Form ___)
    md.LogVerb("Can't train while testing")
  EndEvent

  Event OnInactivityDelta(string _, string __, float delta, Form ___)
    md.LogVerb("Inactivity disabled while testing")
  EndEvent

  Event OnSleep(string _, string __, float ____, Form ___)
    md.LogVerb("Can't gain while testing")
  EndEvent

  Event OnGainsDelta(string _, string __, float delta, Form sender)
    md.LogVerb("Can't gain while testing")
  EndEvent
EndState

;>========================================================
;>===                   APPEARANCE                   ===<;
;>========================================================

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
  return data
EndFunction

; Gets the player appearance from Lua.
int Function _GetAppearance()
  return JValue.evalLuaObj(_InitData(), "return maxick.ChangePlayerAppearance(jobject)")
EndFunction
