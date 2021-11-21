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
Maxick_Events Property ev Auto

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
int _pollingInterval = 5
float _lastPollingTime = 0.0

;>========================================================
;>===                     SETUP                      ===<;
;>========================================================

Event OnInit()
  ; _lastTrained = Now()
  ; _lastPollingTime = Now()
  ; _InitFromMcm()
EndEvent

; Initializes data from MCM settings. Used so the player doesn't have to configure this
; mod each new stealthy archer they create.
Function _InitFromMcm()
  ; SetUpdateInterval(MCM.GetModSettingInt("Max Sick Gains", "iPolling:Other"))
EndFunction

Function OnGameReload()
  RegisterEvents()
EndFunction

; Registers the events needed for this mod to work.
Function RegisterEvents()
  RegisterForModEvent(ev.TRAIN, "OnTrain")
  RegisterForModEvent(ev.GAINS_CHANGE, "OnGainsDelta")
  RegisterForModEvent(ev.TRAINING_CHANGE, "OnTrainDelta")
  RegisterForModEvent(ev.ACTIVITY_CHANGE, "OnInactivityDelta")
  RegisterForModEvent(ev.UPDATE_INTERVAL, "OnGetUpdateInterval")
  RegisterForModEvent(ev.SLEEP, "OnSleep")

  RegisterForModEvent(ev.JOURNEY_AVERAGE, "OnJourneyAverage")
  RegisterForModEvent(ev.JOURNEY_DAYS, "OnJourneyDays")
  RegisterForModEvent(ev.JOURNEY_STAGE, "OnJourneyStage")

  RegisterForModEvent(ev.JOURNEY_STAGE, "OnJourneyStage")

  ; Skyrim Platform communication
  ; RegisterForModEvent(EV_POLLING, "OnMaxickUpdate")
  RegisterForModEvent(EV_SKILL, "OnMaxickSkill")
EndFunction

string EV_SKILL = "Maxick_Skill"

; Player got some training.
Event OnTrain(string _, string skillName, float __, Form ___)
  ; Communicate with Skyrim Platform
  JDB.solveStrSetter(".maxickEv.skillUp", skillName, true)
  SendModEvent(EV_SKILL, skillName)
EndEvent

; WARNING: Do not delete. Blank event used to communicate with Skyrim Platform
Event OnMaxickSkill(string _, string ____, float __, Form ___)
EndEvent

; Dummy event. Used to make sure the logging level was correctly sent to addons.
Event OnGetUpdateInterval(string _, string __, float interval, Form ___)
  md.LogVerb("Polling interval was correctly sent: " + interval)
  ; PO3_SKSEFunctions
EndEvent

; Called from MCM Helper when the user changed the polling interval.
Function SetUpdateInterval(int interval)
EndFunction

;>========================================================
;>===              POLLING CALCULATIONS              ===<;
;>========================================================

; These are done each `n` seconds defined by the player when setting the
; widget refresh rate in the MCM.
Event OnUpdate()
  ; SendModEvent(EV_POLLING)
  ; RegisterForSingleUpdate(3)
  ; _Poll()
EndEvent

;>========================================================
;>===               EVENTS FROM ADDONS               ===<;
;>========================================================

; Player woke up.
; - Set training.
; - Send gains delta.
Event OnSleep(string _, string __, float hoursSlept, Form ___)
  ; md.LogVerb("=====================================")
  ; md.LogVerb("Hours slept: " + hoursSlept)

  ; int data = LuaTable("maxick.OnSleep", hoursSlept, _training, _gains, _stage)
  ; _SetGains( JMap.getFlt(data, "newGains") )
  ; _SetTraining( JMap.getFlt(data, "newTraining") )
  ; _SetStage( JMap.getInt(data, "newStage") )
  ; _SendStageDelta( JMap.getInt(data, "stageDelta") )

  ; SendModEvent( ev.GAINS_CHANGE, "", JMap.getFlt(data, "gainsDelta") )
  ; SendModEvent( ev.JOURNEY_AVERAGE, "", JMap.getFlt(data, "averagePercent") )
  ; SendModEvent( ev.JOURNEY_DAYS, "", JMap.getFlt(data, "daysPercent") )
  ; SendModEvent( ev.JOURNEY_STAGE, "", JMap.getFlt(data, "stagePercent") )

  ; ChangeAppearance()
  ; md.LogVerb("=====================================")
EndEvent

; Player got direct `gains` from an addon.
Event OnGainsDelta(string _, string __, float delta, Form sender)
EndEvent

; Got the value for which the `training` will change.
Event OnTrainDelta(string _, string __, float delta, Form ___)
EndEvent

; Got the value for which the `inactivity` will change.
Event OnInactivityDelta(string _, string __, float delta, Form ___)
EndEvent

Event OnJourneyAverage(string _, string __, float journey, Form ___)
  md.LogInfo("Journey average sucessfully sent: " + journey)
EndEvent

Event OnJourneyStage(string _, string __, float journey, Form ___)
  md.LogVerb("Journey by stage sucessfully sent: " + journey)
EndEvent

Event OnJourneyDays(string _, string __, float journey, Form ___)
  md.LogVerb("Journey by days sucessfully sent: " + journey)
EndEvent

;>========================================================
;>===                   APPEARANCE                   ===<;
;>========================================================

Function EquipPizzaHandsFix(bool wait = true)
EndFunction

Function FixGenitalTextures()
EndFunction

; Sets the correct skin when player changes into werewolf/vampire lord/etc.
Function OnTransformation()
EndFunction

bool Function _IsTransformed()
EndFunction

; Changes player appearance.
Function ChangeAppearance(bool skipMuscleDef = false)
EndFunction
