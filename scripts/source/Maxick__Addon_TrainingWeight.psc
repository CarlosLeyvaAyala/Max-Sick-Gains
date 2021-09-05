Scriptname Maxick__Addon_TrainingWeight extends ObjectReference
{
  Train with sacks when player activated a training sack Activator.
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

This is a standard Max Sick Gains training type, so **you shouldn't** call
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

; What to do when activating a training sack.
Event OnActivate(ObjectReference _)
  _InitVars()
  If !ev || !md
    _ShowInitializationError()
    return
  EndIf

  md.LogVerb("Training sack activated")
  _ShowNormalMenu()
EndEvent

Function _ShowInitializationError()
  ; There's no guarantee Maxick_Debug exists. Print directly.
  MiscUtil.PrintConsole("[Maxick] Events hook: " + ev)
  Debug.MessageBox("Something failed when trying to train with sacks. Report to mod author.")
EndFunction

; Initialize script variables.
Function _InitVars()
  player = Game.GetPlayer()
  ev = Maxick___Compatibility.HookToEvents()
  md = Maxick___Compatibility.HookToDebugging()
EndFunction

; Show the normal menu and act according to selection.
Function _ShowNormalMenu()
  int selection = normalMenu.Show()
  If selection == 0
    If _PlayerIsTired()
      _ShowTiredMenu()
    Else
      _Train()
      ; TODO: Set tired icon
    EndIf
  ElseIf selection == 1
    _Pickup()
  EndIf
EndFunction

; Has the player not gotten a full recovery since last trained with sacks?
bool Function _PlayerIsTired()
  ; TODO: Get last time trained
  return false
EndFunction

Function _ShowTiredMenu()
  If tiredMsg.Show() != 1
    return
  EndIf
  _Train()
  _RiskInjury()
EndFunction

Function _RiskInjury()
  If Utility.RandomFloat() > injuryRisk
    return
  EndIf
  ; TODO: Get injury
  Debug.MessageBox("Congratulations! You pushed yourself too far with your ego lifting and now you got " + "!")
EndFunction

; Perform training maneuvers.
Function _Train()
  md.LogVerb("Player has trained with " + trainingType)
  _FadeOut()
  _AdvanceHours(0.25)     ; Spend 15 minutes training
  ; TODO: Set last time trained
  ; TODO: Reset icon timer
  ev.SendPlayerHasTrained(trainingType)
  _FadeIn()
EndFunction

; Fade out the screen to simulate time passing.
Function _FadeOut()
  Game.DisablePlayerControls()
  Game.FadeOutGame(True, True, 0.5, 1.0)
  Utility.Wait(0.5)
EndFunction

; Fade in the screen to simulate time passing.
Function _FadeIn()
  Utility.Wait(0.5)
  Game.FadeOutGame(False, True, 0.5, 1.0)
  Game.EnablePlayerControls()
EndFunction

; Pick up training weight to inventory.
Function _Pickup()
  player.AddItem(spawner, 1, True)
  DisableNoWait(True)
  Delete()
EndFunction

; How many hours the player spent training.
Function _AdvanceHours(float aHours)
  GameHour.Mod(aHours)
EndFunction
