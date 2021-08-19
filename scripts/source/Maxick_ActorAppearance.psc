Scriptname Maxick_ActorAppearance extends Quest

import Maxick_Utils

FormList Property NakedBodiesList Auto
{A list that contains lists of textures used to change people's muscle definition levels}

;>========================================================
;>===                    SLIDERS                     ===<;
;>========================================================

; Initializes known female and male sliders for the installed body types.
; All posible sliders need to be known before we can change their values on a
; per `Actor` basis.
;
; Generate both files using the **Slider Generator** tool in _Max Sick Gains.exe_.
Function InitSliders()
  int data = JMap.object()
  JMap.setObj(data, "femSliders", _LoadSliders("data/SKSE/Plugins/Maxick/fem-sliders.json"))
  JMap.setObj(data, "manSliders", _LoadSliders("data/SKSE/Plugins/Maxick/man-sliders.json"))
  JDB.setObj("maxick", data)
EndFunction

; Initializes known sliders from some file and inits them at `0.0`.
int Function _LoadSliders(string aPath)
  int result = JMap.object()
  int sliders = JValue.readFromFile(aPath)
  int i = JArray.count(sliders)
  While (i > 0)
    i -= 1
    JMap.setFlt(result, JArray.getStr(sliders, i), 0.0)
  EndWhile
  return result
EndFunction

;>========================================================
;>===                      CORE                      ===<;
;>========================================================

; Tries to apply a Bodyslide preset to an actor based on collected `data`.
Function _ApplyBodyslide(Actor aAct, int bodyslide, float weight)
  If weight >= 0 ; Change shape if not banned from doing so
    NiOverride.ClearMorphs(aAct)

    string slider = JMap.nextKey(bodyslide)
    While slider != ""
      NiOverride.SetMorphValue(aAct, slider, JMap.getFlt(bodyslide, slider))
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

    ActorBase b = aAct.GetBaseObject() as ActorBase
    FormList defType = NakedBodiesList.GetAt(muscleDefType) as FormList
    b.SetSkin(defType.GetAt(muscleDef) as Armor)
    ; FIXME: Check that the actor is not mounting before doing this
    aAct.QueueNiNodeUpdate()
  EndIf
EndFunction

; Changes an actor appearance based on the `data` collected from them.
; `data` is a handle to a `JMap` object.
Function ChangeAppearance(Actor aAct, int data)
  Log(JMap.getStr(data, "msg"))
  If !JMap.getInt(data, "shouldProcess")
    return
  EndIf
  _ApplyBodyslide(aAct, JMap.getObj(data, "bodySlide"), JMap.getFlt(data, "weight"))
  _ApplyMuscleDef(aAct, data)
EndFunction

;>========================================================
;>===                    HELPERS                     ===<;
;>========================================================

; Gets if the actor is a female.
bool Function IsFemale(Actor aAct)
  ; It seems `GetSex()` won't work if used inside a Global function; it can't be added to a library.
  return aAct.GetLeveledActorBase().GetSex() == 1
EndFunction

; Gets the race EDID for an actor as a string.
string Function GetRace(Actor aAct)
  return MiscUtil.GetActorRaceEditorID(aAct)
EndFunction

; Initializes data shared between actors processed by this mod:
; * Sex
; * Sliders
; * Race EDID
; * Muscle definition
; * Muscle definition type
; * Weight
; * Should they be processed? (always 1 for player)
Function InitCommonData(int data, Actor aAct, float weight, int shouldProcess = 1)
  bool isFem = IsFemale(aAct)
  JMap.setInt(data, "isFem", isFem as int)
  If isFem
    JMap.setObj(data, "bodySlide",  JValue.deepCopy(JDB.solveObj(".maxick.femSliders")))
  Else
    JMap.setObj(data, "bodySlide", JValue.deepCopy(JDB.solveObj(".maxick.manSliders")))
  EndIf

  JMap.setStr(data, "raceEDID", GetRace(aAct))
  JMap.setInt(data, "muscleDefType", -1)
  JMap.setInt(data, "muscleDef", -1)
  JMap.setFlt(data, "weight", weight)
  JMap.setInt(data, "shouldProcess", shouldProcess)
EndFunction

;@Deprecated:
; Gets the head node that can be used for applying face overlays using `NiOverride`.
;
; Left here for documentation purposes and it will likely never be used by this mod.
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
