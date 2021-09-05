Scriptname Maxick_Main extends Quest
{Main controler for Max Sick Gains}

Import JValue
Import DM_Utils
Import Maxick_Utils

Actor Property player Auto
; FormList Property NakedBodiesList Auto
; {A list that contains lists of textures used to change people's muscle definition levels}
Maxick_Player Property PcHandler Auto
{Handles everything Player related.}
Maxick_NPC Property NpcHandler Auto
{Handles everything NPC related.}
Maxick_ActorAppearance Property looksHandler Auto
{Handles everything appearance related.}
Maxick_Debug Property md Auto
{Handles everything debgging related.}
Maxick_Widget Property widget Auto
{Widget.}
Maxick_Events Property ev Auto

Spell Property ChangeCellSpell Auto

Event OnInit()
  Utility.Wait(60)    ; Wait some time because too many scripts may fuck this up
  OnGameReload()
  PcHandler.ChangeAppearance()
  player.AddSpell(ChangeCellSpell)
EndEvent

; These functions are called sequentially and not hooked as callbacks because we want to
; make sure these settings are initializated in this precise order.
Function OnGameReload()
  ; JDB.writeToFile(JContainers.userDirectory() + "dump.json")
  md.OnGameReload()
  _RegisterEvents()
  looksHandler.OnGameReload()
  PcHandler.OnGameReload()
  NpcHandler.OnGameReload()
  widget.OnGameReload()
  _TestingModeOperations()
EndFunction

; Main NPC processing function.
Function OnCellLoad()
  GoToState("CellLoading")

  ; https://www.creationkit.com/index.php?title=Unit
  Actor[] npcs = MiscUtil.ScanCellNPCs(player, 0, None, false)
  int i = npcs.length
  While i > 0
    If npcs[i] && (npcs[i] != Player)
      NpcHandler.ChangeAppearance(npcs[i])
    EndIf
    i -= 1
  EndWhile

  GoToState("")
EndFunction

; Things to do when loading a game in testing mode.
Function _TestingModeOperations()
  If !md.testMode
    md.LogVerb("***TESTING MODE DISABLED***")
    return
  EndIf
  md.LogVerb("***TESTING MODE ENABLED***")
  PcHandler.ChangeAppearance()
  OnCellLoad()
EndFunction

;>========================================================
;>===                     EVENTS                     ===<;
;>========================================================

; Registers events needed for this mod to work.
Function _RegisterEvents()
  RegisterForModEvent(ev.CELL_CHANGE, "OnCellChange")
  RegisterForSleep()
  _RegisterForSex()
EndFunction

; Captures when player is having sex.
Function _RegisterForSex()
  If SexLabExists()
    ; RegisterForModEvent("AnimationStart", "SexLabEvent")
    RegisterForModEvent("StageEnd", "SexLabEvent")
    RegisterForModEvent("AnimationEnd", "SexLabEvent")
  EndIf
  RegisterForModEvent("ostim_animationchanged", "OStimEvent")
  RegisterForModEvent("ostim_end", "OStimEvent")
EndFunction

; Apply settings to NPCs when encountering them
Event OnCellChange(string _, string __, float ___, form ____)
  md.LogVerb("Main script got an OnCellChange event.")
  OnCellLoad()
EndEvent

State CellLoading
  Event OnCellChange(string _, string __, float ___, form ____)
    md.LogVerb("Main script got an OnCellChange event, but it's still working on changing NPCs. Ignore.")
  EndEvent
EndState

; OStim integration.
Event OStimEvent(string _, string __, float ___, form ____)
  If OUtils.GetOStim().IsActorActive(player)
    md.LogInfo("OStim event detected")
    SendModEvent(ev.TRAIN, "Sex")
  EndIf
EndEvent

; Sexlab integration.
Event SexLabEvent(string _, string __, float ___, form sender)
  sslThreadController c = sender as sslThreadController
  If c && c.HasPlayer
    md.LogInfo("SexLab event detected")
    SendModEvent(ev.TRAIN, "Sex")
  EndIf
EndEvent

;> Sleeping

; Being in animation (from Posers or something) while sleeping seems to freeze the game. Avoid it.
Function PreparePlayerToSleep()
  If Player.IsWeaponDrawn()
    Player.SheatheWeapon()
  EndIf
EndFunction

; Prepare player to sleep.
Event OnSleepStart(float aStartTime, float aEndTime)
  PreparePlayerToSleep()
  _goneToSleepAt = Now()                        ; Just went to sleep
EndEvent

; What happens when the player wakes up.
Event OnSleepStop(bool aInterrupted)
  If HourSpan(_lastSlept) < 6
    md.LogCrit("You should wait at least 6 hours in-between sleeping sessions to make gains.")
    _lastSlept = Now()
    return
  EndIf

  ; Hours actually slept, since player can cancel or Astrid can kidnap.
  float hoursSlept = HourSpan(_goneToSleepAt)
  If hoursSlept < 1
    Return      ; Do nothing if didn't really slept
  EndIf
  ev.SendSleep(hoursSlept)
  _lastSlept = Now()
EndEvent

float _goneToSleepAt
float _lastSlept
