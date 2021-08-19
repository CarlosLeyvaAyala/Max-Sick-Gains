Scriptname Maxick_Main extends Quest
{Main controler for Max Sick Gains}

Import JValue
import Maxick_Utils

Actor Property Player Auto
; FormList Property NakedBodiesList Auto
; {A list that contains lists of textures used to change people's muscle definition levels}
Maxick_Player Property PcHandler Auto
{Handles everything Player related}
Maxick_NPC Property NpcHandler Auto
{Handles everything NPC related}
Maxick_ActorAppearance Property looksHandler Auto
{Handles everything appearance related}

Event OnInit()
  Player = Game.GetPlayer()
  OnGameReload()
EndEvent

int Function GetDataTree()
  return JDB.solveObj(".maxick")
EndFunction

Function OnGameReload()
  ; JDB.writeToFile(JContainers.userDirectory() + "dump.json")
  Player = Game.GetPlayer()
  looksHandler.InitSliders()
  PcHandler.SetHotkeys()
  OnCellLoad()
  PcHandler.ChangeAppearance()
EndFunction

Function OnCellLoad()
  Actor[] npcs = MiscUtil.ScanCellNPCs(Player, 0, None, false)
  int i = npcs.length
  While i > 0
    If npcs[i] != Player
      NpcHandler.ChangeAppearance(npcs[i])
    EndIf
    i -= 1
  EndWhile
  ; JValue.writeToFile(JDB.solveObj(".maxick"), JContainers.userDirectory() + "Maxick.json")
EndFunction
