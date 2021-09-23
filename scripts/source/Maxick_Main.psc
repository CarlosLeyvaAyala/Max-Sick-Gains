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
  Utility.Wait(10)    ; Wait some time because too many scripts may fuck this up
  OnGameReload()
  PcHandler.ChangeAppearance()
  ; player.AddSpell(ChangeCellSpell)
EndEvent

; Event OnUpdate()
;   _AppearanceByPolling()
; EndEvent

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
  ; _AppearanceByPolling()
EndFunction

; Main NPC processing function.
Function OnCellLoad()
  ; _ChangeNPCsInCell(false)
EndFunction

Function _ChangeNPCsInCell(bool forceAppearance)
  GoToState("CellLoading")
  float t = Utility.GetCurrentRealTime()

  int kNPC = 43 ; https://www.creationkit.com/index.php?title=GetType_-_Form
  Cell kCell = player.GetParentCell()
  Int n = kCell.GetNumRefs(kNPC)
  Actor npc = None
  md.SetLuaLoggingLvl()
  ; This looks horrible, but it's faster than asking the same question each iteration.
  ; Would be trivial to change functions if functions were first class citizens in Papyrus,
  ; but Papyrus is basically a toy language.
  If forceAppearance
    While n
      n -= 1
      npc = kCell.GetNthRef(n, kNPC) as Actor
      If !npc.IsDisabled() && (npc != Player)
        NpcHandler.ForceChangeAppearance(npc)
      EndIf
    EndWhile
  Else
    While n
      n -= 1
      npc = kCell.GetNthRef(n, kNPC) as Actor
      If !npc.IsDisabled() && (npc != Player)
        NpcHandler.ChangeAppearance(npc)
      EndIf
    EndWhile
  EndIf

  md.LogOptim("Changed NPCs in cell in " + (Utility.GetCurrentRealTime() - t) + " seconds")
  GoToState("")
EndFunction

; Sets an appearance to NPCs really close to player. Used for pesky NPCs that simply refuse to change by normal means.
;
; See [Skyrim measure units](https://www.creationkit.com/index.php?title=Unit).
; Function _AppearanceByPolling()
;   UnregisterForUpdate()
;   return
;   GoToState("CellLoading")
;   float t = Utility.GetCurrentRealTime()

;   int kNPC = 43 ; https://www.creationkit.com/index.php?title=GetType_-_Form
;   Cell kCell = player.GetParentCell()
;   Int n = kCell.GetNumRefs(kNPC)
;   Actor npc = None
;   md.SetLuaLoggingLvl()
;   While n
;     n -= 1
;     npc = kCell.GetNthRef(n, kNPC) as Actor
;     If !npc.IsDisabled() && (npc != Player) && (npc.GetDistance(player) < 1024)
;       NpcHandler.ChangeAppearance(npc)
;     EndIf
;   EndWhile

;   md.LogOptim("Changed NPCs around player in " + (Utility.GetCurrentRealTime() - t) + " seconds")
;   RegisterForSingleUpdate(10)
;   GoToState("")
; EndFunction

; State CellLoading
;   Function _AppearanceByPolling()
;     RegisterForSingleUpdate(10)
;   EndFunction
; EndState

; Forces to set an appearance to surrounding NPCs.
; This function bypasses optimizations.
Function ForceSurroundingNPCs()
  md.LogInfo("You tried to forcefully set an appearance on NPCs in current cell.")
  _ChangeNPCsInCell(true)
EndFunction

; Things to do when loading a game in testing mode.
Function _TestingModeOperations()
  If !md.testMode
    md.LogVerb("***TESTING MODE DISABLED***")
    return
  EndIf
  md.LogVerb("***TESTING MODE ENABLED***")
  OnCellLoad()
EndFunction

;>========================================================
;>===                     EVENTS                     ===<;
;>========================================================

; Registers events needed for this mod to work.
Function _RegisterEvents()
  ; RegisterForModEvent(ev.CELL_CHANGE, "OnCellChange")
  ; PO3_Events_Form.RegisterForCellFullyLoaded(self)
  PO3_Events_Form.UnregisterForCellFullyLoaded(self)
  RegisterForSleep()
  _RegisterForSex()
EndFunction

Cell lastLoadedCell = None

; Event OnCellFullyLoaded(Cell akCell)
;   md.LogVerb("Main script got an OnCellFullyLoaded event. Cell name: "  + akCell)
;   ; _ChangeNPCsInCellParallel(akCell)
; endEvent

; Function _ChangeNPCsInCellParallel(Cell aCell)
;   float t = Utility.GetCurrentRealTime()

;   int kNPC = 43 ; https://www.creationkit.com/index.php?title=GetType_-_Form
;   Int n = aCell.GetNumRefs(kNPC)
;   Actor npc = None
;   md.SetLuaLoggingLvl()
;   While n
;     n -= 1
;     npc = aCell.GetNthRef(n, kNPC) as Actor
;     If !npc.IsDisabled() && (npc != Player)
;       NpcHandler.ChangeAppearance(npc)
;     EndIf
;   EndWhile

;   md.LogOptim("Changed NPCs in cell in " + (Utility.GetCurrentRealTime() - t) + " seconds")
; EndFunction

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
  return
  Cell newCell = player.GetParentCell()
  If lastLoadedCell == newCell
    return
  EndIf
  lastLoadedCell = newCell
  md.LogVerb("+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ ")
  md.LogVerb("Player changed cells. New cell: " + newCell)
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
