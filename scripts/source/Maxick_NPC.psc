Scriptname Maxick_NPC extends Quest
{NPC management}

import Maxick_Utils

; FormList Property KnownNPCs Auto
Maxick_Main Property main Auto
Maxick_ActorAppearance Property looksHandler Auto
Maxick_Debug Property md Auto
Maxick_Events Property ev Auto

Function OnGameReload()
EndFunction

Function Test()
  ; Maxick_DB.SaveToFile("DB Dump")

  ; Maxick_DB.CleanMemoizationData()

Maxick___Compatibility.SaveFlt("meh", "flt", 1888)
md.Log("---------------- " + Maxick___Compatibility.GetFlt("meh", "flt", -1))
Maxick_DB.SaveFlt("meh", 188)
md.Log("---------------- " + Maxick_DB.GetFlt("meh", -1))
Maxick_DB.FormSaveFlt(Game.getplayer(), "meh", 3244)
md.Log("---------------- " + Maxick_DB.FormGetFlt(game.getplayer(),"meh", -1))


  ; Actor npc = Game.GetCurrentConsoleRef() as Actor
  ; If !npc
  ;   npc = Game.GetCurrentCrosshairRef() as Actor
  ; EndIf
EndFunction

; Can this NPC get NiOverride data applied?
bool Function CanApplyNiOverride(Actor npc)
  looksHandler.CanApplyNiOverride(npc, Maxick_DB.GetMemoizedAppearance(npc))
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

  float t = Utility.GetCurrentRealTime()
  md.SetLuaLoggingLvl()

  ForceChangeAppearance(npc)

  md.LogOptim("ForceChangeAppearance: " + (Utility.GetCurrentRealTime() - t) + " seconds")
EndFunction

; Gets an npc `ActorBase` by using `GetLeveledActorBase()`.
;
; Was made as a separate function because these alternatives were viable as well
; and may or may not be used instead:
; - npc.GetActorBase() <- Always gets 'dremora' as the NPC class. Not viable.
; - npc.GetBaseObject() <- Always gets 'dremora' as the NPC class. Not viable.
; - npc.GetLeveledActorBase()
ActorBase Function _GetBase(Actor npc)
  return npc.GetLeveledActorBase()
EndFunction

; Known actors are stored in the memory database with their `id` from the Lua database.
; This function gets that `id` or returns `-999` if not found.
int Function _GetKnownNpcId(ActorBase base)
  return Maxick_DB.FormGetInt(base, "knownNpcId", -999)
EndFunction

; Gets all the info needed to apply visual changes to an NPC.
; Returns a handle to a `JMap` (a Lua table, actually) that contains all
; needed data.
; See `init.lua` to learn about the table structure this function creates.
int Function _InitNpcData(Actor npc)
  ActorBase base = _GetBase(npc)

  int data = JMap.object()
  JMap.setStr(data, "name", DM_Utils.GetActorName(npc))
  JMap.setInt(data, "formId", base.GetFormID())
  JMap.setFlt(data, "weight", base.GetWeight())
  JMap.setStr(data, "class", base.GetClass().GetName())
  JMap.setStr(data, "raceEDID", looksHandler.GetRace(npc))
  JMap.setInt(data, "isFem", looksHandler.IsFemale(npc) as int)
  JMap.setInt(data, "knownNpcId", _GetKnownNpcId(base))

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

; Executes the Lua function that makes all calculations on one NPC.
int Function _GetAppearance(Actor npc)
  return JValue.evalLuaObj(_InitNpcData(npc), "return maxick.ChangeNpcAppearance(jobject)")
EndFunction

; Changes the appearance of some NPC based on their data.
Function ChangeAppearance(Actor npc)
  float t = Utility.GetCurrentRealTime()

  ; Optimization step. No longer needed when applying morphs with a spell.
  bool processed = NiOverride.GetBodyMorph(npc, "MaxickProcessed", "Maxick")
  If (processed)
    md.LogVerb("OPTIMIZATION. " + DM_Utils.GetActorName(npc) +" still retains an appearance setting. Skipping.")
    md.LogOptim("ChangeAppearance, optimized by Morph Key: " + (Utility.GetCurrentRealTime() - t) + " seconds")
    return
  EndIf

  ; Optimization step
  int memo = Maxick_DB.GetMemoizedAppearance(npc)
  If memo
    md.LogVerb("OPTIMIZATION. An appearance for " + DM_Utils.GetActorName(npc) + " was already calculated. Will use it instead of calculating it again.")
    JMap.setStr(memo, "msg", "")    ; Calculated log is not needed anymore. Discard
    md.LogOptim("ChangeAppearance, optimized by memoization: " + (Utility.GetCurrentRealTime() - t) + " seconds")
  EndIf

  ForceChangeAppearance(npc, memo)
EndFunction

; Changes an actor appearance while skipping optimizations.
Function ForceChangeAppearance(Actor npc, int appearance = 0)
  bool saveAppearance = false
  If !appearance
    float t = Utility.GetCurrentRealTime()

    appearance = _GetAppearance(npc)
    saveAppearance = true   ; A new appearance was calculated. Save it.

    md.LogOptim("Lua appearance calculation: " + (Utility.GetCurrentRealTime() - t) + " seconds")
  EndIf

  looksHandler.ChangeAppearance(npc, appearance, true)

  ; Memoize data for BaseForm only if it was actually calculated instead of gotten
  ; from memoized data.
  If saveAppearance
    Maxick_DB.MemoizeAppearance(npc, appearance)
  EndIf
  Maxick_DB.JustSeen(npc)
EndFunction

;@Hint: Deprecated
; Checks if the NPC is in the formlist of known NPCs.
; This method is slow and unflexible, but 100% reliable. Left here because I may
; need to use it if the `"Name-class-race(-EDID) Matching"` method doesn't work.
Function _CheckIfNpcIsKnown(ActorBase npc, int data)
  ; If !KnownNPCs.HasForm(npc)
  ;   md.LogCrit("Generic NPC.")
  ;   return
  ; EndIf

  ; Int i = KnownNPCs.GetSize()
  ; While i > 0
  ;   i -= 1
  ;   If npc == KnownNPCs.GetAt(i)
  ;     md.LogCrit("Actor known")
  ;     JMap.setInt(data, "isKnown", i)
  ;     JMap.setInt(data, "shouldProcess", 1)
  ;     return
  ;   EndIf
  ; EndWhile
EndFunction
