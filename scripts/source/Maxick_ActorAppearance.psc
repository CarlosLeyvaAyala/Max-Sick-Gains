Scriptname Maxick_ActorAppearance extends Quest

import Maxick_Utils
import DM_Utils

Maxick_Debug Property md Auto
; Armor Property SkinNakedWerewolfBeast Auto
Armor Property PizzaHandsFix Auto
FormList Property NakedBodiesList Auto
{A list that contains lists of textures used to change people's muscle definition levels}
FormList Property ManNormal_Textures Auto
FormList Property FemNormal_Textures Auto

; Reserved for possible future use.
Function OnGameReload()
  ; player = Game.GetPlayer()
EndFunction

;>========================================================
;>===                      CORE                      ===<;
;>========================================================

; Tries to apply a Bodyslide preset to an actor based on collected `data`.
Function _ApplyBodyslide(Actor aAct, int bodyslide, float weight)
  If weight >= 0 ; Change shape if not banned from doing so
    float t = Utility.GetCurrentRealTime()
    NiOverride.ClearMorphs(aAct)
    ; LuaDebugTable(bodyslide, GetActorName(aAct))

    string slider = JMap.nextKey(bodyslide)
    While slider != ""
      NiOverride.SetBodyMorph(aAct, slider, "Maxick", JMap.getFlt(bodyslide, slider))
      slider = JMap.nextKey(bodyslide, slider)
    EndWhile

    NiOverride.UpdateModelWeight(aAct)
    NiOverride.SetBodyMorph(aAct, "MaxickProcessed", "Maxick", 1) ; Need to mark the actor again due to clearing bodyslides
    md.LogVerb("Bodyslide applied in " + (Utility.GetCurrentRealTime() - t) + " seconds")
  EndIf
EndFunction

; Tries to apply muscle definition to an actor based on collected `data`.
Function ApplyMuscleDef(Actor aAct, int data)
  string muscleDef = JMap.getStr(data, "muscleDef")
  If muscleDef == ""
    return ; Banned from changing muscle definition
  EndIf

  _EquipPizzaHandsFix(aAct)
  NiOverride.AddSkinOverrideString(aAct, true, false, 0x4, 9, 1, muscleDef, true)
  aAct.RemoveItem(PizzaHandsFix, 1, true)
EndFunction

; Equips the naked gauntlets to solve the dreaded _"Pizza Hands Syndrome"_ if necessary.
; This only equips the gauntlets if the actor had none equiped, since **that bug only happens
; when setting skin overrides while being TOTALLY naked**.
Function _EquipPizzaHandsFix(Actor aAct)
  If !(aAct.GetWornForm(0x8) as Armor)
    aAct.EquipItem(PizzaHandsFix, false, true)
    Utility.Wait(0.05)   ; Helps avoiding NiOverride to act before the hand armor is set on the actor.
  EndIf
EndFunction

; Changes an actor appearance based on the `data` collected from them.
; `data` is a handle to a `JMap` object.
Function ChangeAppearance(Actor aAct, int data)
  NiOverride.SetBodyMorph(aAct, "MaxickProcessed", "Maxick", 1) ; Mark an invalid actor as processed

  md.Log(JMap.getStr(data, "msg"))
  If !JMap.getInt(data, "shouldProcess")
    return
  EndIf
  _ApplyBodyslide(aAct, JMap.getObj(data, "bodySlide"), JMap.getFlt(data, "weight"))
  ApplyMuscleDef(aAct, data)
EndFunction

; Changes the head size of an `Actor`.
Function ChangeHeadSize(Actor aAct, float size)
  string headNode = "NPC Head [Head]"
  If NetImmerse.HasNode(aAct, headNode, False)
    NetImmerse.SetNodeScale(aAct, headNode, size, False)
    UpdateNiNode(aAct)
  EndIf
EndFunction

;>========================================================
;>===                    HELPERS                     ===<;
;>========================================================

; Updates a NiNode when conditions are right.
Function UpdateNiNode(Actor aAct)
  If aAct.IsOnMount()
    md.LogCrit("ERROR: Can't update a character while mounting.")
    return
  EndIf
  aAct.QueueNiNodeUpdate()
EndFunction

; Gets if the actor is a female.
bool Function IsFemale(Actor aAct)
  ; It seems `GetSex()` won't work if used inside a Global function; it can't be added to a library.
  return aAct.GetLeveledActorBase().GetSex() == 1
EndFunction

; Gets the race EDID for an actor as a string.
string Function GetRace(Actor aAct)
  return MiscUtil.GetActorRaceEditorID(aAct)
EndFunction

;@Deprecated:
; Gets the head node that can be used for applying face overlays using `NiOverride`.
;
; Left here for documentation purposes, since it will likely never be used by this mod.
;
; Sample use:
; ```
; NiOverride.AddSkinOverrideString(aAct, true, false, 0x04, 9, 0, "data\\textures\\actors\\character\\f.dds", true)
; string head = _GetHeadNode(aAct)
; If head != ""
;   NiOverride.AddNodeOverrideString(aAct, true, head, 9, 0, "data\\textures\\actors\\character\\he.dds", true)
; EndIf
; ```
;
; Skin override [slot masks reference](https://www.creationkit.com/index.php?title=Slot_Masks_-_Armor).
string Function _GetHeadNode(Actor aAct)
  ActorBase ab = aAct.GetActorBase()
  int i = ab.GetNumHeadParts()
  string headNode
  While i > 0
    i -= 1
    headNode = ab.GetNthHeadPart(i).GetPartName()
    If StringUtil.Find(headNode, "Head") >= 0
      return headNode
    EndIf
  endWhile
  return ""
EndFunction

; TODO: Add compatibilty with Growl
Armor Function _GetWerewolfSkin()
  ; Vanilla wolf skin
  return Game.GetFormFromFile(0xCDD87, "Skyrim.esm") as Armor
EndFunction
