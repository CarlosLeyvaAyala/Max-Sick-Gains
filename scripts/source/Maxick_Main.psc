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
  Player = Game.GetPlayer()
  looksHandler.InitSliders()
  ; JDB.writeToFile(JContainers.userDirectory() + "dump.json")
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
  ; _TestMorphs(Player)
EndFunction

  ; https://www.creationkit.com/index.php?title=Slot_Masks_-_Armor
  ;> ##############################################################
  ;> DON'T USE. Hands problem also affects difuse maps.
  ;> ##############################################################
  ; NiOverride.AddSkinOverrideString(aAct, true, false, 0x04, 9, 0, "data\\textures\\actors\\character\\f.dds", true)
  ; string head = _GetHeadNode(aAct)
  ; If head != ""
  ;   NiOverride.AddNodeOverrideString(aAct, true, head, 9, 0, "data\\textures\\actors\\character\\he.dds", true)
  ; EndIf

  ; <SetSlider.*name\s*="(.*)".*"big".*="(.*)"\/>
  ; NiOverride.SetMorphValue(aAct, "\1", 0.\2)

; string Function _GetHeadNode(Actor aAct)
;   ActorBase ab = aAct.GetActorBase()
;   int i = ab.GetNumHeadParts()
;   string headNode
;   While i > 0
;       i -= 1
;       headNode = ab.GetNthHeadPart(i).GetPartName()
;       If StringUtil.Find(headNode, "Head") >= 0
;         return headNode
;       EndIf
;   endWhile
;   return ""
; EndFunction
