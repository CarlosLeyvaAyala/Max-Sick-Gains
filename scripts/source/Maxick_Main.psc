Scriptname Maxick_Main extends Quest
{Main controler for Max Sick Gains}

Import JValue
import Maxick_Utils

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

Event OnInit()
  OnGameReload()
EndEvent

int Function GetDataTree()
  return JDB.solveObj(".maxick")
EndFunction

Function OnGameReload()
  ; JDB.writeToFile(JContainers.userDirectory() + "dump.json")
  md.OnGameReload()
  looksHandler.OnGameReload()
  PcHandler.OnGameReload()
  _TestingModeOperations()
EndFunction

; Main NPC processing function.
Function OnCellLoad()
  Actor[] npcs = MiscUtil.ScanCellNPCs(player, 0, None, false)
  int i = npcs.length
  While i > 0
    If npcs[i] != Player
      NpcHandler.ChangeAppearance(npcs[i])
    EndIf
    i -= 1
  EndWhile
  ; JValue.writeToFile(JDB.solveObj(".maxick"), JContainers.userDirectory() + "Maxick.json")
EndFunction

Function _TestingModeOperations()
  ; FIXME: Activate only in Testing mode
  PcHandler.ChangeAppearance()
  OnCellLoad()
EndFunction
