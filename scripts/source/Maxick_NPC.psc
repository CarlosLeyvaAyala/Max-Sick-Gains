Scriptname Maxick_NPC extends Quest
{NPC management}

import Maxick_Utils

FormList Property KnownNPCs Auto
Maxick_Main Property main Auto
Maxick_ActorAppearance Property looksHandler Auto

; Gets all the info needed to apply visual changes to an NPC.
; Returns a handle to a `JMap` (a Lua table, actually) that contains all
; needed data.
; See `init.lua` to learn about the table structure this function creates.
int Function _InitNpcData(Actor npc)
  ; Alternatives:
  ; npc.GetActorBase()
  ; npc.GetBaseObject()
  ActorBase base = npc.GetLeveledActorBase()

  int data = JMap.object()
  JMap.setStr(data, "name", DM_Utils.GetActorName(npc))
  JMap.setInt(data, "formId", base.GetFormID())
  JMap.setInt(data, "isKnown", 0)
  JMap.setStr(data, "msg", "")              ; Extra info from Lua

  looksHandler.InitCommonData(data, npc, base.GetWeight(), 0)

  JMap.setInt(data, "fitStage", 1)        ; Set the default stage from MaxSickGains.exe
  JMap.setStr(data, "racialGroup", "")    ; Lua will get this
  JMap.setStr(data, "raceDisplay", "")    ; Lua will get this
  JMap.setStr(data, "class", base.GetClass().GetName())
  ; JMap.setInt(data, "shouldProcess", 0)   ; We still don't know if we are going to process it

  ; _CheckIfNpcIsKnown(npc, data)
  return data
EndFunction

; Executes the Lua function that makes all calculations on one NPC
int Function _GetAppearance(Actor npc)
  Log("NPC found: '" + DM_Utils.GetActorName(npc) + "'")
  int data = _InitNpcData(npc)
  return JValue.evalLuaObj(data, "return maxick.ProcessNPC(jobject)")
EndFunction

; Changes the appearance of some NPC based on their data.
Function ChangeAppearance(Actor npc)
  looksHandler.ChangeAppearance(npc, _GetAppearance(npc))
EndFunction

;@Hint: Deprecated
; Checks if the NPC is in the formlist of known NPCs.
; This method is slow and unflexible, but 100% reliable. Left here because I may
; need to use it if the `"Name-class-race(-EDID) Matching"` method doesn't work.
Function _CheckIfNpcIsKnown(ActorBase npc, int data)
  If !KnownNPCs.HasForm(npc)
    Log("Generic NPC.")
    return
  EndIf

  Int i = KnownNPCs.GetSize()
  While i > 0
    i -= 1
    If npc == KnownNPCs.GetAt(i)
      Log("Actor known")
      JMap.setInt(data, "isKnown", i)
      JMap.setInt(data, "shouldProcess", 1)
      return
    EndIf
  EndWhile
EndFunction


; https://www.creationkit.com/index.php?title=Unit
; JValue.writeToFile(JDB.solveObj("." + root), JContainers.userDirectory() + "Maxick.json")
; MiscUtil.PrintConsole(JContainers.userDirectory() + "Maxick.json")