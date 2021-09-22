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

; Returns a `TextureSet` that contains a normal map corresponding to some calculated data.
TextureSet Function _GetNormalTexture(FormList list, int racialGroup, int muscleDefType, int muscleDef)
  FormList rg = list.GetAt(racialGroup) as FormList
  FormList mt = rg.GetAt(muscleDefType) as FormList
  return mt.GetAt(muscleDef - 1) as TextureSet
EndFunction

; Tries to apply muscle definition to an actor based on collected `data`.
; See this [technical document](https://github.com/CarlosLeyvaAyala/Max-Sick-Gains/blob/master/technical%20docs/muscle-definition.md) to understand this method.
Function _ApplyMuscleDef(Actor aAct, int data)
  int muscleDefType = JMap.getInt(data, "muscleDefType", -1)
  int muscleDef = JMap.getInt(data, "muscleDef", -1)
  If muscleDefType < 0 || muscleDef < 0  ; Not banned from changing muscle definition
    return
  EndIf

  FormList defType = NakedBodiesList.GetAt(muscleDefType) as FormList
  _SetSkin(aAct, defType.GetAt(muscleDef) as Armor)
EndFunction

; Returns the file path for the normal texture set that will be applied to an actor
string Function _NormalTexturePath(Actor aAct, int racialGroup, int muscleDefType, int muscleDef)
  FormList musclesList
  If IsFemale(aAct)
    musclesList = FemNormal_Textures
  Else
    musclesList = ManNormal_Textures
  EndIf
  return _GetNormalTexture(musclesList, racialGroup, muscleDefType, muscleDef).GetNthTexturePath(1)
EndFunction

; Tries to apply muscle definition to an actor based on collected `data`.
Function ApplyMuscleDef(Actor aAct, int data)
  int muscleDefType = JMap.getInt(data, "muscleDefType", -1)
  int muscleDef = JMap.getInt(data, "muscleDef", -1)
  int racialGroup = JMap.getInt(data, "racialGroup", -1)
  md.LogVerb(DM_Utils.GetActorName(aAct) +": applying muscle definition. " + muscleDefType + " " + muscleDef + " " + racialGroup)
  If muscleDefType < 0 || muscleDef < 1 || racialGroup < 0
    return ; Banned from changing muscle definition
  EndIf

  string normalMapPath = _NormalTexturePath(aAct, racialGroup, muscleDefType, muscleDef)
  md.LogVerb("Normal map to apply: " + normalMapPath)

  _EquipPizzaHandsFix(aAct)
  NiOverride.AddSkinOverrideString(aAct, true, false, 0x4, 9, 1, normalMapPath, true)
  aAct.RemoveItem(PizzaHandsFix, 1, true)
EndFunction

; Equips the naked gauntlets to solve the dreaded _"Pizza Hands Syndrome"_ if necessary.
; This only equips the gauntlets if the actor had none equiped, since **that bug only happens
; when setting skin overrides while being TOTALLY naked**.
Function _EquipPizzaHandsFix(Actor aAct)
  If !(aAct.GetWornForm(0x8) as Armor)
    aAct.EquipItem(PizzaHandsFix, false, true)
    Utility.Wait(0.1)   ; Helps avoiding NiOverride to act before the hand armor is set on the actor.
  EndIf
EndFunction

Function TestMuscleDef(Actor npc)
  ; int type = Utility.RandomInt(0, 2)
  ; int def = Utility.RandomInt(1, 6)
  int type = 1
  int def = 6

  _EquipPizzaHandsFix(npc)
  TextureSet fem = _GetNormalTexture(FemNormal_Textures, 0, type, def)
  NiOverride.AddSkinOverrideString(npc, true, false, 0x4, 9, 1, fem.GetNthTexturePath(1), true)
  npc.RemoveItem(PizzaHandsFix, 1, true)
EndFunction

Function MakeWerewolf(Actor aAct)
  ; _SetSkin(aAct, _GetWerewolfSkin())
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
