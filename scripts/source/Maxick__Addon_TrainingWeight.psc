Scriptname Maxick__Addon_TrainingWeight extends ObjectReference
{
  Train with sacks when player activated a training sack Activator.

  Maxick___Compatibility script is used for making integrations.
  If you want to make a mod integration with mine, look at both
  the source code for that script and all the places where that
  script was used in this file.
}

Message Property normalMenu Auto
{What does the player want to do with this item?}

Message Property tiredMsg Auto
{What to do when the player is still sore?}

int Property hoursToRest = 72 Auto
{How many hours will this sack make the player tired.}

MiscObject Property spawner Auto
{Item that originally spawned this Activator}

GlobalVariable Property GameHour Auto
{Points to GameHour global. Used to advance time after training.}

string Property trainingType Auto
{
What kind of training this sack gives?

Possible values:
- "SackS"
- "SackM"
- "SackL"

Since this is a standard Max Sick Gains training type, **you shouldn't** call
`Maxick_Events.SendTrainingAndActivity()`, but `Maxick_Events.SendPlayerHasTrained()`
instead.
}

float Property injuryRisk Auto
{
  How much likely you are of getting injured by training while tired.
  Value between [0..1].
}

Actor player

; Hook to Max Sick Gains events.
Maxick_Events ev
; Hook to Max Sick Gains debugging functions.
Maxick_Debug md

; This is used for saving data related to this addon.
; When you do your own addon, make sure to select a name no one except you will likely use.
string addonName = "officialTrainingSacks"

; Remove tired icon after some time passes.
Event OnUpdateGameTime()
  ; Need to check this because another training session (one with an injury risk) may have extended the tired time.
  If PlayerIsTired()
    return
  EndIf
  ; TODO: Remove tired icon
endEvent

; What to do when activating a training sack.
Event OnActivate(ObjectReference _)
  InitVars()
  If !ev || !md
    ShowInitializationError()
    return
  EndIf

  md.LogVerb("Training sack activated")
  ShowNormalMenu()
EndEvent

Event OnEquipped(Actor _)
  InitVars()
  If !ev || !md
    ShowInitializationError()
    return
  EndIf

  md.LogVerb("Training sack activated")
  ShowNormalMenu()
EndEvent

Function ShowInitializationError()
  ; There's no guarantee Maxick_Debug exists. Print directly.
  MiscUtil.PrintConsole("[Maxick] Events hook: " + ev)
  Debug.MessageBox("Something failed when trying to train with sacks. Report to mod author.")
EndFunction

; Initialize script variables.
Function InitVars()
  player = Game.GetPlayer()
  ev = Maxick___Compatibility.HookToEvents()
  md = Maxick___Compatibility.HookToDebugging()
EndFunction

; Show the normal menu and act according to selection.
Function ShowNormalMenu()
  int selection = normalMenu.Show()
  If selection == 0
    If PlayerIsTired()
      ShowTiredMenu()
    Else
      Train()
      ; TODO: Set tired icon
    EndIf
  ElseIf selection == 1
    Pickup()
  EndIf
EndFunction

; Has the player not gotten a full recovery since last trained with sacks?
bool Function PlayerIsTired()
  float notTired = Maxick___Compatibility.GetFlt(addonName, "notTiredAt")
  float now = DM_Utils.Now()

  md.LogVerb("Expected time not to be tired: " + notTired)
  md.LogVerb("Now: " + now)

  return notTired > now
EndFunction

; Shows a different set of training options when still tired from last session.
Function ShowTiredMenu()
  If tiredMsg.Show() != 1
    return    ; Player chose wisely not to train
  EndIf
  Train()
  RiskInjury()
EndFunction

Function RiskInjury()
  If Utility.RandomFloat() > injuryRisk
    return
  EndIf
  ; TODO: Get injury
  ; TODO: Hurt training and gains
  Debug.MessageBox("Congratulations! You pushed yourself too far with your ego lifting and now you got " + "!")
EndFunction

; Perform training maneuvers.
Function Train()
  md.LogVerb("Player has trained with " + trainingType)

  FadeOut()
  AdvanceHours(0.25)     ; Spend 15 minutes training
  SetRecoveryHour()
  ev.SendPlayerHasTrained(trainingType)
  FadeIn()
  RegisterForSingleUpdateGameTime(Maxick___Compatibility.ToSkyrimHours(hoursToRest)) ; Reset tired icon timer
EndFunction

; Sets the hour at which the player can safely train again.
Function SetRecoveryHour()
  float now = DM_Utils.Now()
  float recoveryHour = now + Maxick___Compatibility.ToSkyrimHours(hoursToRest)
  Maxick___Compatibility.SaveFlt(addonName, "notTiredAt", recoveryHour)

  md.LogVerb("Trained with sack at time: " + now)
  md.LogVerb("Player will be ready to train again at: " + Maxick___Compatibility.GetFlt(addonName, "notTiredAt"))
EndFunction

; Fade out the screen to simulate time passing.
Function FadeOut()
  Game.DisablePlayerControls()
  Game.FadeOutGame(True, True, 0.5, 1.0)
  Utility.Wait(0.5)
EndFunction

; Fade in the screen to simulate time passing.
Function FadeIn()
  Utility.Wait(0.5)
  Game.FadeOutGame(False, True, 0.5, 1.0)
  Game.EnablePlayerControls()
EndFunction

; Pick up training weight to inventory.
Function Pickup()
  ; player.AddItem(spawner, 1, True)
  ; DisableNoWait(True)
  ; Delete()
EndFunction

; How many hours the player spent training.
Function AdvanceHours(float aHours)
  GameHour.Mod(aHours)
EndFunction
