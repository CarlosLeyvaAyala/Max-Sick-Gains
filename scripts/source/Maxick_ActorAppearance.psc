Scriptname Maxick_ActorAppearance extends Quest

import Maxick_Utils
import DM_Utils

Maxick_Debug Property md Auto
Armor Property SkinNakedWerewolfBeast Auto
FormList Property NakedBodiesList Auto
{A list that contains lists of textures used to change people's muscle definition levels}

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
    NiOverride.ClearMorphs(aAct)
    ; LuaDebugTable(bodyslide, GetActorName(aAct))

    string slider = JMap.nextKey(bodyslide)
    While slider != ""
      NiOverride.SetBodyMorph(aAct, slider, "Maxick", JMap.getFlt(bodyslide, slider))
      slider = JMap.nextKey(bodyslide, slider)
    EndWhile

    NiOverride.UpdateModelWeight(aAct)
  EndIf
EndFunction

; Tries to apply muscle definition to an actor based on collected `data`.
; See this [technical document](https://github.com/CarlosLeyvaAyala/Max-Sick-Gains/blob/master/technical%20docs/muscle-definition.md) to understand this method.
Function _ApplyMuscleDef(Actor aAct, int data)
  int muscleDefType = JMap.getInt(data, "muscleDefType")
  If muscleDefType >= 0 ; Not banned from changing muscle definition
    int muscleDef = JMap.getInt(data, "muscleDef")
    If muscleDef < 0    ; Banned from changing muscle definition
      return  ; Should never get here, but still added it as a redundant safeguard
    EndIf

    FormList defType = NakedBodiesList.GetAt(muscleDefType) as FormList
    _SetSkin(aAct, defType.GetAt(muscleDef) as Armor)
  EndIf
EndFunction

Function MakeWerewolf(Actor aAct)
  _SetSkin(aAct, _GetWerewolfSkin())
EndFunction

Function _SetSkin(Actor aAct, Armor skin)
  ActorBase b = aAct.GetBaseObject() as ActorBase
  b.SetSkin(skin)
  UpdateNiNode(aAct)
EndFunction

; Changes an actor appearance based on the `data` collected from them.
; `data` is a handle to a `JMap` object.
Function ChangeAppearance(Actor aAct, int data)
  md.Log(JMap.getStr(data, "msg"))
  If !JMap.getInt(data, "shouldProcess")
    return
  EndIf
  _ApplyBodyslide(aAct, JMap.getObj(data, "bodySlide"), JMap.getFlt(data, "weight"))
  _ApplyMuscleDef(aAct, data)
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
