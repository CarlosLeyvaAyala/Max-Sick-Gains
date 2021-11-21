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

bool _clearAllOverrides
bool Property clearAllOverrides Hidden
  {
    Has the user enabled the experimental method to avoid save game bloat?
    See `Maxick_ActorAppearanceSpell.Clear()` to know what this is used for.
  }
    bool Function Get()
      return _clearAllOverrides
    EndFunction
  EndProperty

Function OnGameReload()
EndFunction

; This function is also called by MCM Helper when changing this `bClearAllOverrides`.
Function SetClearAllOverrides(bool value)
EndFunction

; Equips the naked gauntlets to solve the dreaded _"Pizza Hands Syndrome"_ if necessary.
; This only equips the gauntlets if the actor had none equipped, since **that bug only happens
; when setting skin overrides while being TOTALLY naked**.
Function EquipPizzaHandsFix(Actor aAct, bool wait = true)
EndFunction


;>========================================================
;>===                      CORE                      ===<;
;>========================================================

; Changes an actor appearance based on the `data` collected from them.
; `data` is a handle to a `JMap` object.
Function ChangeAppearance(Actor aAct, int data, bool useNiOverride = false, bool skipMuscleDef = false)
EndFunction

; Changes the head size of an `Actor`.
Function ChangeHeadSize(Actor aAct, float size)
EndFunction

; Clears data added by this mod.
Function Clear(Actor aAct)
EndFunction

; Clears skin overrides added by this mod
Function _ClearSkinOverrides(Actor aAct)
EndFunction

; Clears morphs added by this mod.
Function _ClearMorphs(Actor aAct)
EndFunction


;>========================================================
;>===               MUSCLE DEFINITION                ===<;
;>========================================================

; Can this actor get NiOverride data applied?
bool Function CanApplyNiOverride(Actor aAct, int data)
EndFunction

; Fixes vagina and anus textures on females.
; Note this function needs to be applied each time the armor is un/equiped, because nodes can disappear depending on the armor.
Function FixGenitalTextures(Actor aAct)
EndFunction

;>========================================================
;>===                    HELPERS                     ===<;
;>========================================================

; Updates a NiNode when conditions are right.
Function UpdateNiNode(Actor aAct)
EndFunction

; Gets if the actor is a female.
bool Function IsFemale(Actor aAct)
EndFunction

; Gets the race EDID for an actor as a string.
string Function GetRace(Actor aAct)
EndFunction

bool Function IsChild(Actor aAct)
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
