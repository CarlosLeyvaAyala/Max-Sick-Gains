Scriptname Maxick_NPC extends Quest
{NPC management}

import Maxick_Utils

Maxick_Main Property main Auto

; `JFormMap` of NPCs the player explicitly set to process in **MaxSickGains.exe**
int _knownNpcs
ActorBase _base

; Initializes data needed for this to work
Function Init(Maxick_Main owner)
  main = owner
  _knownNpcs = JValue.readFromFile("data/SKSE/Plugins/Maxick/npcs.json")
EndFunction

; Does it's best to find the base of an NPC.
; Skyrim is weird and some functions return the correct base while others don't.
Function _FindActorBase(Actor npc)
  _base = npc.GetLeveledActorBase()
  if !JFormMap.hasKey(_knownNpcs, _base)
    Log("Fail 1")
    _base = npc.GetActorBase()
    if !JFormMap.hasKey(_knownNpcs, _base)
      Log("Fail 2")
      _base = npc.GetBaseObject() as ActorBase
    endif
  endif
EndFunction

; Gets the data needed to process an NPC.
; Sets the `_base` private variable, too.
int Function _InitNpcData(Actor npc)
  int data = JMap.object()
  JMap.setStr(data, "msg", "")              ; Extra info from Lua

  bool isFem = main.IsFemale(npc)
  JMap.setInt(data, "isFem", isFem as int)
  If isFem
    JMap.setObj(data, "bodySlide", main.femSliders)
  EndIf

  _FindActorBase(npc)

  JMap.setFlt(data, "weight", _base.GetWeight())
  JMap.setInt(data, "fitStage", 1)        ; Set the default stage from MaxSickGains.exe
  JMap.setInt(data, "muscleDefType", -1)
  JMap.setInt(data, "muscleDef", -1)
  JMap.setInt(data, "shouldProcess", 0)   ; We still don't know if we are going to process it

  ; TODO: Get race and class
  return data
EndFunction

; Adds the data for an NPC the player explicitly asked to process when
; using the NPCs tab in **MaxSickGains.exe**
int Function _GetExplicitData(int data)
  int values = JFormMap.getObj(_knownNpcs, _base)

  JMap.setInt(data, "fitStage", JMap.getInt(values, "fitStage"))
  JMap.setInt(data, "weight", JMap.getInt(values, "weight"))
  JMap.setInt(data, "muscleDef", JMap.getInt(values, "muscleDef"))
  JMap.setInt(data, "shouldProcess", 1)

  return data
EndFunction

; Gets all the info needed about applying visual changes to an NPC.
; Returns a handle to a `JMap` (a Lua table, actually) that contains all
; needed data.
; See `init.lua` to learn about the table structure this function creates.
int Function ProcessNpc(Actor npc)
  Log("NPC found: '" + DM_Utils.GetActorName(npc) + "'")
  int data = _InitNpcData(npc)

  ; _base was already found in _GetNpcData()
  If JFormMap.hasKey(_knownNpcs, _base)
    Log("*** Explicitly added NPC *** " + DM_Utils.GetActorName(npc))
    data = _GetExplicitData(data)
    return JValue.evalLuaObj(data, "return maxick.ProcessKnownNPC(jobject)")
  Else
    Log(DM_Utils.GetActorName(npc) + " is not a known actor. If you explicitly added it, don't worry. Skyrim is weird and it eventually recognize it.")
    JMap.setInt(data, "shouldProcess", 0)
  EndIf

  return 0

EndFunction




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
