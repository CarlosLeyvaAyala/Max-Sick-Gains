Scriptname Maxick_NPC extends Quest
{NPC management}

import Maxick_Utils

FormList Property KnownNPCs Auto
Maxick_Main Property main Auto

; Initializes data needed for this to work
; Function Init(Maxick_Main owner)
;   main = owner
; EndFunction

; Gets all the info needed to apply visual changes to an NPC.
; Returns a handle to a `JMap` (a Lua table, actually) that contains all
; needed data.
; See `init.lua` to learn about the table structure this function creates.
int Function _InitNpcData(Actor npc)
  ActorBase base = npc.GetLeveledActorBase()

  int data = JMap.object()
  JMap.setStr(data, "name", DM_Utils.GetActorName(npc))
  JMap.setInt(data, "formId", base.GetFormID())
  JMap.setInt(data, "isKnown", 0)
  JMap.setStr(data, "msg", "")              ; Extra info from Lua

  bool isFem = main.IsFemale(npc)
  JMap.setInt(data, "isFem", isFem as int)
  If isFem
    JMap.setObj(data, "bodySlide",  JValue.deepCopy(JDB.solveObj(".maxick.femSliders")))
  Else
    JMap.setObj(data, "bodySlide", JValue.deepCopy(JDB.solveObj(".maxick.manSliders")))
  EndIf

  JMap.setFlt(data, "weight", base.GetWeight())
  JMap.setInt(data, "fitStage", 1)        ; Set the default stage from MaxSickGains.exe
  JMap.setInt(data, "muscleDefType", -1)
  JMap.setInt(data, "muscleDef", -1)
  JMap.setStr(data, "raceEDID", main.GetRace(npc))
  JMap.setStr(data, "race", "")           ; Lua will get this
  JMap.setStr(data, "racialGroup", "")    ; Lua will get this
  JMap.setStr(data, "raceDisplay", "")    ; Lua will get this
  JMap.setStr(data, "class", base.GetClass().GetName())
  JMap.setInt(data, "shouldProcess", 0)   ; We still don't know if we are going to process it

  ; _CheckIfNpcIsKnown(npc, data)
  return data
EndFunction

; Executes the Lua function that makes all calculations on one NPC
int Function ProcessNpc(Actor npc)
  Log("Testing NPC: '" + DM_Utils.GetActorName(npc) + "'")
  int data = _InitNpcData(npc)
  return JValue.evalLuaObj(data, "return maxick.ProcessNPC(jobject)")
EndFunction

; Function _CheckIfNpcIsKnown(Actor npc, int data)
;   ; Alternatives:
;   ; npc.GetActorBase()
;   ; npc.GetBaseObject()
;   ActorBase b = npc.GetLeveledActorBase()
;   Log(DM_Utils.IntToHex(b.GetFormID()))
;   Log(main.GetRace(npc))
;   Log(b.GetClass().GetName())
;   If !KnownNPCs.HasForm(b)
;     Log("Unknown actor shouldnt be processed")
;     return
;   EndIf

;   Int i = KnownNPCs.GetSize()
;   While i > 0
;     i -= 1
;     If b == KnownNPCs.GetAt(i)
;       Log("Actor known")
;       JMap.setInt(data, "isKnown", i)
;       JMap.setInt(data, "shouldProcess", 1)
;     EndIf
;   EndWhile
; EndFunction

; Adds the data for an NPC the player explicitly asked to process when
; using the NPCs tab in **MaxSickGains.exe**
; int Function _GetExplicitData(int data)
;   JMap.setInt(data, "fitStage", JMap.getInt(values, "fitStage"))
;   JMap.setInt(data, "weight", JMap.getInt(values, "weight"))
;   JMap.setInt(data, "muscleDef", JMap.getInt(values, "muscleDef"))
;   JMap.setInt(data, "shouldProcess", 1)

;   return data
; EndFunction

; First time TextureSet setting for actors
; TODO: Delete this when everything is nice and tidy. Used for reference because it works.
Function _SetTextureSets()
  string root = "maxickGains"
  ; https://www.creationkit.com/index.php?title=Unit
  Actor[] npcs = MiscUtil.ScanCellNPCs(None, 0, None, false)
  ; Actor[] npcs = MiscUtil.ScanCellNPCs(Player, 0, None, false)
  int i = npcs.length
  While i > 0
      i -= 1
      Actor npc = npcs[i]
      ActorBase b = npc.GetBaseObject() as ActorBase
      ; int rand = Utility.RandomInt(0, 2)
      ; b.SetSkin(NakedBodiesList.GetAt(1) as Armor)
      ; npc.QueueNiNodeUpdate()

      ; MiscUtil.PrintConsole("###########################################")
      ; MiscUtil.PrintConsole(DM_Utils.GetActorName(npc))
      ; MiscUtil.PrintConsole("b skin = " + b.GetSkin())
      ; MiscUtil.PrintConsole("b skin = " + b.GetFormID())
      ; MiscUtil.PrintConsole("b rand = " + rand)
      ; MiscUtil.PrintConsole("b class = " + b.GetClass().GetName())
      ; MiscUtil.PrintConsole("###########################################")

      ; MiscUtil.PrintConsole("b class = " + b.GetClass())
      ; MiscUtil.PrintConsole("l class = " + npc.GetLeveledActorBase().GetClass())
      ; MiscUtil.PrintConsole("l class = " + npc.GetLeveledActorBase().GetClass().GetName())
  EndWhile
  ; JValue.writeToFile(JDB.solveObj("." + root), JContainers.userDirectory() + "Maxick.json")
  ; MiscUtil.PrintConsole(JContainers.userDirectory() + "Maxick.json")
EndFunction
