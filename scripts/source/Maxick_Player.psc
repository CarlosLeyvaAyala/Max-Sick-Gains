Scriptname Maxick_Player extends Quest
{Player management}

import Maxick_Utils

Maxick_Main Property main Auto
Maxick_ActorAppearance Property looksHandler Auto

int hkGains0
int hkGains100
int hkNextLvl
int hkPrevLvl
int hkSlideshow

Actor player
float _gains = 0.0

Event OnInit()
  player = Game.GetPlayer()
EndEvent


;>========================================================
;>===                  TESTING MODE                  ===<;
;>========================================================

Function SetHotkeys()
  hkGains0 = 203
  hkGains100 = 205
  hkPrevLvl = 208
  hkNextLvl = 200
  hkSlideshow = 28
  RegisterForKey(hkGains0)
  RegisterForKey(hkGains100)
  RegisterForKey(hkPrevLvl)
  RegisterForKey(hkNextLvl)
  RegisterForKey(hkSlideshow)
EndFunction

Event OnKeyDown(Int KeyCode)
  If KeyCode == hkGains0
    _gains = 0.0
    ChangeAppearance()
  EndIf
  If KeyCode == hkGains100
    _gains = 100.0
    ChangeAppearance()
  EndIf
  If KeyCode == hkSlideshow
    _gains = 0.0
    ; TODO: stage = 1
    ChangeAppearance()
    Debug.Notification("Started slideshow")
    RegisterForSingleUpdate(_slStepTime)
    GotoState("Slideshow")
  EndIf
EndEvent

float _slStepTime = 0.5
State Slideshow
  Event OnUpdate()
    _gains += 10.0
    ChangeAppearance()
    RegisterForSingleUpdate(_slStepTime)
    If (_gains >= 100.0)
      GotoState("")
      UnregisterForUpdate()
      Debug.Notification("Slideshow ended")
    EndIf
  EndEvent

  Event OnKeyDown(Int KeyCode)
    If KeyCode == hkSlideshow
      ; TODO: Stop slideshow
      GotoState("")
    EndIf
  EndEvent
EndState

;>========================================================
;>===                   APPEARANCE                   ===<;
;>========================================================

Function ChangeAppearance()
  looksHandler.ChangeAppearance(player, _GetAppearance())
EndFunction

Function TrainSkill(string aSkill)
  ; code
EndFunction

int Function _InitData()
  int data = JMap.object()

  ; Weight is irrelevant. Is only set so `looksHandler.ChangeAppearance` sets the
  ; Bodyslide preset.
  looksHandler.InitCommonData(data, player, 0)

  JMap.setInt(data, "stage", 1)       ; Current player stage
  JMap.setFlt(data, "training", 0)
  JMap.setFlt(data, "gains", _gains)
  JMap.setFlt(data, "headSize", 0.0)

  JMap.setInt(data, "evChangeStage", 0)

  return data
EndFunction

int Function _GetAppearance()
  return JValue.evalLuaObj(_InitData(), "return maxick.ChangePlayerAppearance(jobject)")
EndFunction
