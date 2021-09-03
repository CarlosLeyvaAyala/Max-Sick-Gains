Scriptname Maxick_NPC extends Quest
{NPC management}

import Maxick_Utils

FormList Property KnownNPCs Auto
Maxick_Main Property main Auto
Maxick_ActorAppearance Property looksHandler Auto
Maxick_Debug Property md Auto
Maxick_EventNames Property ev Auto

Function OnGameReload()
EndFunction

; Force an NPC to get updated.
Function ForceUpdate()
  md.LogVerb("Forcing change on NPC.")
  Actor npc = Game.GetCurrentConsoleRef() as Actor
  _ForceNPCUpdate(npc)
EndFunction

Function ForceUpdateCrosshair()
  md.LogVerb("Forcing change on NPC.")
  Actor npc = Game.GetCurrentCrosshairRef() as Actor
  _ForceNPCUpdate(npc)
EndFunction

Function _ForceNPCUpdate(Actor npc)
  If !npc
    return
  EndIf
  If npc == main.player
    md.Log("Yeah... nice try, Einstein. GO EARN YOUR GAINS, YOU LOAFER.")
    return
  EndIf
  ForceChangeAppearance(npc)
EndFunction

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
  JMap.setFlt(data, "weight", base.GetWeight())
  JMap.setStr(data, "class", base.GetClass().GetName())
  JMap.setStr(data, "raceEDID", looksHandler.GetRace(npc))
  JMap.setInt(data, "isFem", looksHandler.IsFemale(npc) as int)
  ; looksHandler.InitCommonData(data, npc, base.GetWeight(), 0)

  string mod = "Max Sick Gains"
  int mcmOptions = JMap.object()
  JMap.setInt(mcmOptions, "kNpcBs", MCM.GetModSettingBool(mod, "bKNBsFem:Appearance") as int)
  JMap.setInt(mcmOptions, "kNpcMuscleDef", MCM.GetModSettingBool(mod, "bKNMusDefFem:Appearance") as int)
  JMap.setInt(mcmOptions, "gNpcFemBs", MCM.GetModSettingBool(mod, "bUNBsFem:Appearance") as int)
  JMap.setInt(mcmOptions, "gNpcFemMuscleDef", MCM.GetModSettingBool(mod, "bUNMusDefFem:Appearance") as int)
  JMap.setInt(mcmOptions, "gNpcManBs", MCM.GetModSettingBool(mod, "bUNBsMan:Appearance") as int)
  JMap.setInt(mcmOptions, "gNpcManMuscleDef", MCM.GetModSettingBool(mod, "bUNMusDefMan:Appearance") as int)
  JMap.setObj(data, "mcm", mcmOptions)
  return data
EndFunction

; Executes the Lua function that makes all calculations on one NPC
int Function _GetAppearance(Actor npc)
  md.LogCrit("NPC found: '" + DM_Utils.GetActorName(npc) + "'")
  return JValue.evalLuaObj(_InitNpcData(npc), "return maxick.ChangeNpcAppearance(jobject)")
EndFunction

; Changes the appearance of some NPC based on their data.
Function ChangeAppearance(Actor npc)
  ; First crude optimization step
  string[] morphs = NiOverride.GetMorphNames(npc)
  If morphs.Length > 0
    md.LogInfo("An appearance for " + DM_Utils.GetActorName(npc) + " was already set. Skipping.")
    return
  EndIf
  ForceChangeAppearance(npc)
EndFunction

; Changes an actor appearance regardless of optimizations.
Function ForceChangeAppearance(Actor npc)
  looksHandler.ChangeAppearance(npc, _GetAppearance(npc))
EndFunction

;@Hint: Deprecated
; Checks if the NPC is in the formlist of known NPCs.
; This method is slow and unflexible, but 100% reliable. Left here because I may
; need to use it if the `"Name-class-race(-EDID) Matching"` method doesn't work.
Function _CheckIfNpcIsKnown(ActorBase npc, int data)
  If !KnownNPCs.HasForm(npc)
    md.LogCrit("Generic NPC.")
    return
  EndIf

  Int i = KnownNPCs.GetSize()
  While i > 0
    i -= 1
    If npc == KnownNPCs.GetAt(i)
      md.LogCrit("Actor known")
      JMap.setInt(data, "isKnown", i)
      JMap.setInt(data, "shouldProcess", 1)
      return
    EndIf
  EndWhile
EndFunction
